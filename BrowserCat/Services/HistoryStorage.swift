import Foundation
import os

final class HistoryStorage {
    static let shared = HistoryStorage()

    private let fileManager = FileManager.default

    func save(_ entries: [HistoryEntry]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entries)
            try data.write(to: ConfigDirectory.history, options: .atomic)
            Log.settings.debug("Saved \(entries.count) history entries")
        } catch {
            Log.settings.error("Failed to save history: \(error.localizedDescription)")
        }
    }

    func load() -> [HistoryEntry] {
        guard fileManager.fileExists(atPath: ConfigDirectory.history.path) else { return [] }
        do {
            let data = try Data(contentsOf: ConfigDirectory.history)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let entries = try decoder.decode([HistoryEntry].self, from: data)
            Log.settings.debug("Loaded \(entries.count) history entries")
            return entries
        } catch {
            Log.settings.error("Failed to load history: \(error.localizedDescription)")
            return []
        }
    }
}
