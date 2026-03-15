import Foundation
import FoundationModels
import SwiftUI

@MainActor
class RephraseService: ObservableObject {
    @Published var isProcessing = false
    @Published var statusMessage: String?
    @Published var isError = false
    @Published var lastResult: String?

    var historyStore: HistoryStore?

    private let systemPrompt = """
        You are a text editor assistant. \
        Rephrase the given text to make it clearer, more natural and polished. \
        Keep the original meaning and language. \
        Return ONLY the rephrased text, without any explanations, intro or quotes.
        """

    func rephraseSelectedText() async {
        guard !isProcessing else { return }
        isProcessing = true
        isError = false
        statusMessage = "Copying selected text..."
        lastResult = nil

        // Step 1: Copy selected text via ⌘C
        guard let text = await ClipboardManager.copySelectedText() else {
            statusMessage = "No text selected or clipboard empty"
            isError = true
            isProcessing = false
            return
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "Selected text is empty"
            isError = true
            isProcessing = false
            return
        }

        // Step 2: Check model availability
        guard SystemLanguageModel.default.availability == .available else {
            statusMessage = "Apple Intelligence is not available on this device"
            isError = true
            isProcessing = false
            return
        }

        // Step 3: Rephrase with FoundationModels
        statusMessage = "Rephrasing..."
        do {
            let session = LanguageModelSession(instructions: systemPrompt)
            let response = try await session.respond(to: trimmed)
            let result = response.content

            // Step 4: Paste result back
            ClipboardManager.setClipboard(result)
            await ClipboardManager.pasteFromClipboard()

            lastResult = result
            statusMessage = "Done!"
            isError = false

            // Save to history
            historyStore?.add(original: trimmed, rephrased: result)
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
            isError = true
        }

        isProcessing = false
    }
}
