import Foundation
import SwiftUI

struct HistoryEntry: Identifiable, Codable {
    let id: UUID
    let original: String
    let rephrased: String
    let date: Date

    init(original: String, rephrased: String) {
        self.id = UUID()
        self.original = original
        self.rephrased = rephrased
        self.date = Date()
    }
}

@MainActor
class HistoryStore: ObservableObject {
    @Published var entries: [HistoryEntry] = []

    private static let storageKey = "rephrase_history"
    private static let maxEntries = 200

    init() {
        load()
    }

    func add(original: String, rephrased: String) {
        let entry = HistoryEntry(original: original, rephrased: rephrased)
        entries.insert(entry, at: 0)
        if entries.count > Self.maxEntries {
            entries = Array(entries.prefix(Self.maxEntries))
        }
        save()
    }

    func remove(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    func clearAll() {
        entries.removeAll()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else { return }
        entries = decoded
    }
}
