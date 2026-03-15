import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let triggerRephrase = Self("triggerRephrase", default: .init(.r, modifiers: [.command, .option, .shift]))
}

@main
struct AiRephraseApp: App {
    @StateObject private var rephraseService = RephraseService()
    @StateObject private var historyStore = HistoryStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(rephraseService)
                .environmentObject(historyStore)
        } label: {
            Image(systemName: rephraseService.isProcessing ? "ellipsis.circle" : "text.quote")
        }
        .menuBarExtraStyle(.window)

        Window("History", id: "history") {
            HistoryView()
                .environmentObject(historyStore)
        }
        .defaultSize(width: 700, height: 500)
    }
}

struct MenuBarView: View {
    @EnvironmentObject var service: RephraseService
    @EnvironmentObject var history: HistoryStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rephrase")
                    .font(.headline)
                Spacer()
                KeyboardShortcuts.Recorder("Hotkey:", name: .triggerRephrase)
                    .fixedSize()
            }

            Divider()

            if let status = service.statusMessage {
                HStack(spacing: 6) {
                    if service.isProcessing {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(status)
                        .font(.callout)
                        .foregroundStyle(service.isError ? .red : .secondary)
                }
            }

            if let result = service.lastResult {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Result:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(result)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            Divider()

            HStack {
                Button("Rephrase Selected Text") {
                    Task { await service.rephraseSelectedText() }
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(service.isProcessing)

                Spacer()

                Button("History") {
                    openWindow(id: "history")
                    NSApp.activate(ignoringOtherApps: true)
                }

                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(12)
        .frame(width: 360)
        .onAppear {
            service.historyStore = history
            KeyboardShortcuts.onKeyUp(for: .triggerRephrase) {
                Task { await service.rephraseSelectedText() }
            }
        }
    }
}

// MARK: - History Window

struct HistoryView: View {
    @EnvironmentObject var store: HistoryStore
    @State private var searchText = ""
    @State private var selectedEntry: HistoryEntry?

    private var filtered: [HistoryEntry] {
        if searchText.isEmpty { return store.entries }
        let q = searchText.lowercased()
        return store.entries.filter {
            $0.original.lowercased().contains(q) || $0.rephrased.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationSplitView {
            List(filtered, selection: $selectedEntry) { entry in
                HistoryRow(entry: entry)
                    .tag(entry)
                    .contextMenu {
                        Button("Copy Original") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(entry.original, forType: .string)
                        }
                        Button("Copy Rephrased") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(entry.rephrased, forType: .string)
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            if let idx = store.entries.firstIndex(where: { $0.id == entry.id }) {
                                store.entries.remove(at: idx)
                            }
                        }
                    }
            }
            .searchable(text: $searchText, prompt: "Search history...")
            .frame(minWidth: 260)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(role: .destructive) {
                        store.clearAll()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(store.entries.isEmpty)
                    .help("Clear all history")
                }
            }
        } detail: {
            if let entry = selectedEntry {
                HistoryDetail(entry: entry)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("Select an entry")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Rephrase History")
    }
}

struct HistoryRow: View {
    let entry: HistoryEntry

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.original)
                .lineLimit(2)
                .font(.system(size: 12))
            Text(Self.dateFmt.string(from: entry.date))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

struct HistoryDetail: View {
    let entry: HistoryEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Original
                VStack(alignment: .leading, spacing: 8) {
                    Label("Original", systemImage: "text.alignleft")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.original)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Image(systemName: "arrow.down")
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)

                // Rephrased
                VStack(alignment: .leading, spacing: 8) {
                    Label("Rephrased", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.rephrased)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.accentColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Actions
                HStack {
                    Button("Copy Original") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(entry.original, forType: .string)
                    }
                    Button("Copy Rephrased") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(entry.rephrased, forType: .string)
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(24)
        }
    }
}

// Make HistoryEntry work with List selection
extension HistoryEntry: Hashable {
    static func == (lhs: HistoryEntry, rhs: HistoryEntry) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
