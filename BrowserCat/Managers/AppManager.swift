import Foundation
import os

@MainActor
final class AppManager {
    private let appDetector = AppDetector()

    func refreshApps(into state: AppState) {
        let detected = appDetector.detectApps()
        let savedConfigs = SettingsStorage.shared.loadAppConfigs()

        if let savedConfigs {
            state.apps = mergeDetectedWithSaved(
                detected: detected,
                saved: savedConfigs,
                configID: \.id,
                sortOrder: \.sortOrder
            ) { app, config in
                app.isVisible = config.isVisible
                app.hotkey = config.hotkey?.first
                app.hotkeyKeyCode = config.hotkeyKeyCode ?? config.hotkey?.first.flatMap { KeyCodeMap.keyCode(for: $0) }
                app.sortOrder = config.sortOrder
                app.displayName = config.displayName
            }
        } else {
            state.apps = detected
        }

        save(state.apps)
    }

    func save(_ apps: [InstalledApp]) {
        SettingsStorage.shared.saveAppConfigs(apps)
    }

    // MARK: - Merge Logic

    private func mergeDetectedWithSaved<Item: Identifiable, Config>(
        detected: [Item],
        saved: [Config],
        configID: (Config) -> String,
        sortOrder: WritableKeyPath<Item, Int>,
        apply: (inout Item, Config) -> Void
    ) -> [Item] where Item.ID == String {
        let savedMap = Dictionary(saved.map { (configID($0), $0) }, uniquingKeysWith: { first, _ in first })
        let detectedMap = Dictionary(detected.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        var result: [Item] = []
        var seenIDs: Set<String> = []

        for config in saved {
            let id = configID(config)
            guard seenIDs.insert(id).inserted else { continue }
            if var item = detectedMap[id] {
                apply(&item, config)
                result.append(item)
            }
        }

        let maxOrder = result.map { $0[keyPath: sortOrder] }.max() ?? -1
        var nextOrder = maxOrder + 1
        for item in detected where !savedMap.keys.contains(item.id) {
            var newItem = item
            newItem[keyPath: sortOrder] = nextOrder
            result.append(newItem)
            nextOrder += 1
        }

        return result.sorted { $0[keyPath: sortOrder] < $1[keyPath: sortOrder] }
    }
}
