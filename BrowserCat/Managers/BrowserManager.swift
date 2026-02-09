import Foundation
import os

@MainActor
final class BrowserManager {
    private let browserDetector = BrowserDetector()
    private let profileDetector = ProfileDetector()

    func refreshBrowsers(into state: AppState) {
        let detected = browserDetector.detectBrowsers()
        let savedConfigs = SettingsStorage.shared.loadBrowserConfigs()

        if let savedConfigs {
            state.browsers = mergeDetectedWithSaved(
                detected: detected,
                saved: savedConfigs,
                configID: \.id,
                sortOrder: \.sortOrder
            ) { browser, config in
                browser.isVisible = config.isVisible
                browser.isIgnored = config.isIgnored
                browser.hotkey = config.hotkey?.first
                browser.hotkeyKeyCode = config.hotkeyKeyCode ?? config.hotkey?.first.flatMap { KeyCodeMap.keyCode(for: $0) }
                browser.sortOrder = config.sortOrder
                browser.displayName = config.displayName
            }
        } else {
            state.browsers = detected
        }

        // Detect profiles for each browser and restore saved hotkeys
        let savedConfigMap = savedConfigs.map {
            Dictionary($0.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        }
        for i in state.browsers.indices {
            state.browsers[i].profiles = profileDetector.detectProfiles(for: state.browsers[i])

            let savedConfig = savedConfigMap?[state.browsers[i].id]
            if let savedConfig {
                let profileKeys = savedConfig.profileHotkeys
                let profileKeyCodes = savedConfig.profileHotkeyKeyCodes
                let profileVisibility = savedConfig.profileVisibility
                for j in state.browsers[i].profiles.indices {
                    let dirName = state.browsers[i].profiles[j].directoryName
                    if let key = profileKeys?[dirName] {
                        state.browsers[i].profiles[j].hotkey = key.first
                        state.browsers[i].profiles[j].hotkeyKeyCode =
                            profileKeyCodes?[dirName] ?? key.first.flatMap { KeyCodeMap.keyCode(for: $0) }
                    }
                    if let visible = profileVisibility?[dirName] {
                        state.browsers[i].profiles[j].isVisible = visible
                    }
                }
            }
        }

        save(state.browsers)
    }

    func save(_ browsers: [InstalledBrowser]) {
        SettingsStorage.shared.saveBrowserConfigs(browsers)
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

        // First: add items in saved order (if still installed)
        for config in saved {
            let id = configID(config)
            guard seenIDs.insert(id).inserted else { continue }
            if var item = detectedMap[id] {
                apply(&item, config)
                result.append(item)
            }
        }

        // Second: add newly detected items not in saved config
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
