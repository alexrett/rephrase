import Foundation
import FoundationModels
import SwiftUI
import UserNotifications

enum RephraseBackend: String {
    case appleIntelligence = "Apple Intelligence"
    case ollama = "Ollama"
    case none = "None"
}

@Generable
struct RephrasedText {
    @Guide(description: "The improved version of the input text with better grammar, spelling, and natural phrasing. Keep the same meaning and language. Do not answer the text, only rewrite it.")
    var rewritten: String
}

@MainActor
class RephraseService: ObservableObject {
    @Published var isProcessing = false
    @Published var statusMessage: String?
    @Published var isError = false
    @Published var lastResult: String?
    @Published var activeBackend: RephraseBackend = .none
    @Published var preferredBackend: RephraseBackend? = nil // nil = auto
    @Published var ollamaModel: String = ""
    @Published var availableOllamaModels: [String] = []
    @Published var appleIntelligenceAvailable = false
    @Published var ollamaAvailable = false

    var historyStore: HistoryStore?

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func notify(_ title: String, _ body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private let systemPrompt = """
        You are a proofreading tool. \
        The user gives you text they wrote. \
        Rewrite it with better grammar, spelling, and natural phrasing. \
        Keep the same meaning, tone, and language. \
        Do not answer questions found in the text. Only rewrite them.
        """

    func detectBackend() async {
        appleIntelligenceAvailable = SystemLanguageModel.default.availability == .available

        let models = await OllamaService.listModels()
        ollamaAvailable = !models.isEmpty
        if ollamaAvailable {
            availableOllamaModels = models
            if ollamaModel.isEmpty { ollamaModel = models[0] }
        }

        if let preferred = preferredBackend {
            switch preferred {
            case .appleIntelligence where appleIntelligenceAvailable:
                activeBackend = .appleIntelligence
                statusMessage = "Using Apple Intelligence"
                isError = false
                return
            case .ollama where ollamaAvailable:
                activeBackend = .ollama
                statusMessage = "Using Ollama (\(ollamaModel))"
                isError = false
                return
            default:
                preferredBackend = nil
            }
        }

        if appleIntelligenceAvailable {
            activeBackend = .appleIntelligence
            statusMessage = "Using Apple Intelligence"
            isError = false
        } else if ollamaAvailable {
            activeBackend = .ollama
            statusMessage = "Using Ollama (\(ollamaModel))"
            isError = false
        } else {
            activeBackend = .none
            statusMessage = "No backend available. Enable Apple Intelligence or start Ollama."
            isError = true
        }
    }

    func switchBackend(to backend: RephraseBackend) async {
        preferredBackend = backend
        await detectBackend()
    }

    func triggerRephrase() {
        Task.detached { [weak self] in
            await self?.rephraseSelectedText()
        }
    }

    func rephraseSelectedText() async {
        guard !isProcessing else { return }
        isProcessing = true
        isError = false
        statusMessage = "Copying selected text..."
        lastResult = nil

        guard let text = await ClipboardManager.copySelectedText() else {
            statusMessage = "No text selected or clipboard empty"
            isError = true
            isProcessing = false
            notify("Rephrase", "No text selected. Check Accessibility permissions in System Settings.")
            return
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "Selected text is empty"
            isError = true
            isProcessing = false
            return
        }

        if activeBackend == .none {
            await detectBackend()
        }

        guard activeBackend != .none else {
            isProcessing = false
            return
        }

        statusMessage = "Rephrasing via \(activeBackend.rawValue)..."
        print("[Rephrase] Starting rephrase via \(activeBackend.rawValue), text: \(trimmed.prefix(50))...")
        do {
            let result: String

            switch activeBackend {
            case .appleIntelligence:
                let session = LanguageModelSession(instructions: systemPrompt)
                let response = try await session.respond(to: trimmed, generating: RephrasedText.self)
                result = response.content.rewritten
                print("[Rephrase] Apple Intelligence returned: \(result.prefix(80))...")

            case .ollama:
                result = try await OllamaService.rephrase(trimmed, model: ollamaModel)
                print("[Rephrase] Ollama returned: \(result.prefix(80))...")

            case .none:
                isProcessing = false
                return
            }

            ClipboardManager.setClipboard(result)
            await ClipboardManager.pasteFromClipboard()

            lastResult = result
            statusMessage = "Done! (\(activeBackend.rawValue))"
            isError = false

            historyStore?.add(original: trimmed, rephrased: result)
            notify("Rephrase", "Done!")
            print("[Rephrase] Success, pasted back")
        } catch {
            print("[Rephrase] ERROR: \(error)")
            let msg = friendlyError(error)
            statusMessage = msg
            isError = true
            notify("Rephrase Error", msg)
        }

        isProcessing = false
    }

    private func friendlyError(_ error: Error) -> String {
        let desc = String(describing: error)
        if desc.contains("unsupportedLanguageOrLocale") {
            return "Apple Intelligence doesn't support this language. Switch to Ollama."
        }
        if desc.contains("guardrailViolation") {
            return "Apple Intelligence blocked this text as sensitive. Switch to Ollama."
        }
        if desc.contains("cancel") {
            return "Request was cancelled."
        }
        return "Error: \(error.localizedDescription)"
    }
}
