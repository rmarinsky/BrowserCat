import Foundation
import os

@MainActor
final class HistoryManager {
    func load(into state: AppState) {
        state.history = SettingsStorage.shared.loadHistory()
    }

    func record(url: URL, title: String?, appName: String, profileName: String?, state: AppState) {
        let domain = url.host ?? url.absoluteString
        let entry = HistoryEntry(
            url: url.absoluteString,
            domain: domain,
            title: title,
            appName: appName,
            profileName: profileName
        )
        state.history.insert(entry, at: 0)
        SettingsStorage.shared.saveHistory(state.history)
        Log.history.debug("Recorded history entry for \(domain)")
    }

    func delete(ids: Set<UUID>, state: AppState) {
        state.history.removeAll { ids.contains($0.id) }
        SettingsStorage.shared.saveHistory(state.history)
        Log.history.debug("Deleted \(ids.count) history entries")
    }

    func clearAll(state: AppState) {
        state.history.removeAll()
        SettingsStorage.shared.saveHistory(state.history)
        Log.history.debug("Cleared all history")
    }
}
