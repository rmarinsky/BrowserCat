import AppKit
import os
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    let browserDetector = BrowserDetector()
    let appDetector = AppDetector()
    let browserLauncher = BrowserLauncher()
    let profileDetector = ProfileDetector()
    let urlRuleMatcher = URLRuleMatcher()

    private var pickerController: PickerWindowController?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_: Notification) {
        // Register as URL handler
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        // Detect browsers and apps, merge with saved config
        refreshBrowsers()
        refreshApps()

        // Load URL rules
        loadURLRules()

        // Check default browser status
        checkDefaultBrowserStatus()

        Log.app.info("BrowserCat launched")
    }

    // MARK: - URL Handling

    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor, withReply _: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString)
        else {
            Log.app.error("Received invalid URL event")
            return
        }

        Log.app.info("Received URL: \(urlString)")
        appState.pendingURL = url
        appState.pendingURLTitle = nil
        fetchTitle(for: url)

        // Check URL rules before showing picker
        if let rule = urlRuleMatcher.findMatchingRule(for: url, rules: appState.urlRules) {
            switch rule.targetType {
            case .browser:
                if let browser = appState.browsers.first(where: { $0.id == rule.browserID }) {
                    let profile = rule.profileDirectoryName.flatMap { dirName in
                        browser.profiles.first { $0.directoryName == dirName }
                    }
                    openURL(with: browser, profile: profile)
                    return
                }
            case .app:
                if let app = appState.apps.first(where: { $0.id == rule.browserID }) {
                    openURL(with: app)
                    return
                }
            }
        }

        showPicker()
    }

    // MARK: - Picker

    func showPicker() {
        guard appState.pendingURL != nil else { return }

        if pickerController == nil {
            pickerController = PickerWindowController(appState: appState, delegate: self)
        }
        pickerController?.show()
        appState.isPickerVisible = true
    }

    func dismissPicker() {
        pickerController?.close()
        appState.isPickerVisible = false
    }

    // MARK: - Browser Actions

    func openURL(with browser: InstalledBrowser, mode: BrowserLauncher.OpenMode = .normal, profile: BrowserProfile? = nil) {
        guard let url = appState.pendingURL else { return }
        browserLauncher.open(url: url, with: browser, mode: mode, profile: profile)
        completeURLOpen(url)
    }

    func openURL(with app: InstalledApp) {
        guard let url = appState.pendingURL else { return }
        browserLauncher.open(url: url, with: app)
        completeURLOpen(url)
    }

    private func completeURLOpen(_ url: URL) {
        appState.lastOpenedURL = url.absoluteString
        SettingsStorage.shared.lastURL = url.absoluteString
        appState.pendingURL = nil
        appState.pendingURLTitle = nil
        dismissPicker()
    }

    private func fetchTitle(for url: URL) {
        Task.detached(priority: .utility) {
            do {
                var request = URLRequest(url: url, timeoutInterval: 3)
                request.httpMethod = "GET"
                // Only fetch the beginning of the page
                request.setValue("bytes=0-8192", forHTTPHeaderField: "Range")
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let html = String(data: data, encoding: .utf8) else { return }

                // Extract <title>...</title>
                guard let startRange = html.range(of: "<title", options: .caseInsensitive),
                      let closeTag = html[startRange.upperBound...].range(of: ">"),
                      let endRange = html[closeTag.upperBound...].range(of: "</title>", options: .caseInsensitive)
                else { return }

                let title = String(html[closeTag.upperBound..<endRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !title.isEmpty else { return }

                await MainActor.run {
                    // Only update if we're still showing the same URL
                    if self.appState.pendingURL == url {
                        self.appState.pendingURLTitle = title
                    }
                }
            } catch {
                // Silently ignore - title is optional
            }
        }
    }

    func reopenLastURL() {
        guard let urlString = appState.lastOpenedURL,
              let url = URL(string: urlString)
        else { return }

        appState.pendingURL = url
        showPicker()
    }

    // MARK: - Browser Management

    func refreshBrowsers() {
        let totalStart = CFAbsoluteTimeGetCurrent()

        var mark = CFAbsoluteTimeGetCurrent()
        let detected = browserDetector.detectBrowsers()
        Log.app.debug("⏱ refreshBrowsers: detectBrowsers took \((CFAbsoluteTimeGetCurrent() - mark) * 1000, format: .fixed(precision: 1))ms")

        mark = CFAbsoluteTimeGetCurrent()
        let savedConfigs = SettingsStorage.shared.loadBrowserConfigs()
        Log.app.debug("⏱ refreshBrowsers: loadBrowserConfigs took \((CFAbsoluteTimeGetCurrent() - mark) * 1000, format: .fixed(precision: 1))ms")

        if let savedConfigs {
            mark = CFAbsoluteTimeGetCurrent()
            appState.browsers = mergeDetectedWithSaved(
                detected: detected,
                saved: savedConfigs,
                configID: \.id,
                sortOrder: \.sortOrder
            ) { browser, config in
                browser.isVisible = config.isVisible
                browser.isIgnored = config.isIgnored
                browser.hotkey = config.hotkey?.first
                browser.sortOrder = config.sortOrder
                browser.displayName = config.displayName
            }
            Log.app.debug("⏱ refreshBrowsers: mergeBrowsers took \((CFAbsoluteTimeGetCurrent() - mark) * 1000, format: .fixed(precision: 1))ms")
        } else {
            appState.browsers = detected
        }

        // Detect profiles for each browser and restore saved hotkeys
        mark = CFAbsoluteTimeGetCurrent()
        let savedConfigMap = savedConfigs.map {
            Dictionary($0.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        }
        for i in appState.browsers.indices {
            let profileStart = CFAbsoluteTimeGetCurrent()
            appState.browsers[i].profiles = profileDetector.detectProfiles(for: appState.browsers[i])

            // Restore profile hotkeys from saved config
            if let profileKeys = savedConfigMap?[appState.browsers[i].id]?.profileHotkeys {
                for j in appState.browsers[i].profiles.indices {
                    let dirName = appState.browsers[i].profiles[j].directoryName
                    if let key = profileKeys[dirName] {
                        appState.browsers[i].profiles[j].hotkey = key.first
                    }
                }
            }

            let profileElapsed = (CFAbsoluteTimeGetCurrent() - profileStart) * 1000
            let name = appState.browsers[i].displayName
            if profileElapsed > 5 {
                Log.app.debug("⏱ refreshBrowsers: detectProfiles for \(name) took \(profileElapsed, format: .fixed(precision: 1))ms")
            }
        }
        Log.app.debug("⏱ refreshBrowsers: all profiles took \((CFAbsoluteTimeGetCurrent() - mark) * 1000, format: .fixed(precision: 1))ms")

        mark = CFAbsoluteTimeGetCurrent()
        saveBrowserConfig()
        Log.app.debug("⏱ refreshBrowsers: saveBrowserConfig took \((CFAbsoluteTimeGetCurrent() - mark) * 1000, format: .fixed(precision: 1))ms")

        Log.app.debug("⏱ refreshBrowsers: TOTAL \((CFAbsoluteTimeGetCurrent() - totalStart) * 1000, format: .fixed(precision: 1))ms")
    }

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

    func saveBrowserConfig() {
        SettingsStorage.shared.saveBrowserConfigs(appState.browsers)
    }

    // MARK: - App Management

    func refreshApps() {
        let totalStart = CFAbsoluteTimeGetCurrent()

        var mark = CFAbsoluteTimeGetCurrent()
        let detected = appDetector.detectApps()
        Log.apps.debug("⏱ refreshApps: detectApps took \((CFAbsoluteTimeGetCurrent() - mark) * 1000, format: .fixed(precision: 1))ms")

        mark = CFAbsoluteTimeGetCurrent()
        let savedConfigs = SettingsStorage.shared.loadAppConfigs()
        Log.apps.debug("⏱ refreshApps: loadAppConfigs took \((CFAbsoluteTimeGetCurrent() - mark) * 1000, format: .fixed(precision: 1))ms")

        if let savedConfigs {
            mark = CFAbsoluteTimeGetCurrent()
            appState.apps = mergeDetectedWithSaved(
                detected: detected,
                saved: savedConfigs,
                configID: \.id,
                sortOrder: \.sortOrder
            ) { app, config in
                app.isVisible = config.isVisible
                app.hotkey = config.hotkey?.first
                app.sortOrder = config.sortOrder
                app.displayName = config.displayName
            }
            Log.apps.debug("⏱ refreshApps: mergeApps took \((CFAbsoluteTimeGetCurrent() - mark) * 1000, format: .fixed(precision: 1))ms")
        } else {
            appState.apps = detected
        }

        mark = CFAbsoluteTimeGetCurrent()
        saveAppConfig()
        Log.apps.debug("⏱ refreshApps: saveAppConfig took \((CFAbsoluteTimeGetCurrent() - mark) * 1000, format: .fixed(precision: 1))ms")

        Log.apps.debug("⏱ refreshApps: TOTAL \((CFAbsoluteTimeGetCurrent() - totalStart) * 1000, format: .fixed(precision: 1))ms")
    }

    func saveAppConfig() {
        SettingsStorage.shared.saveAppConfigs(appState.apps)
    }

    // MARK: - URL Rules

    func loadURLRules() {
        appState.urlRules = SettingsStorage.shared.loadURLRules()
    }

    func saveURLRules() {
        SettingsStorage.shared.saveURLRules(appState.urlRules)
    }

    // MARK: - Default Browser

    func checkDefaultBrowserStatus() {
        let start = CFAbsoluteTimeGetCurrent()
        guard let httpURL = URL(string: "https://example.com"),
              let defaultApp = NSWorkspace.shared.urlForApplication(toOpen: httpURL),
              let selfURL = Bundle.main.bundleURL as URL?
        else {
            appState.isDefaultBrowser = false
            Log.app.debug("⏱ checkDefaultBrowserStatus: failed guard, took \((CFAbsoluteTimeGetCurrent() - start) * 1000, format: .fixed(precision: 1))ms")
            return
        }
        appState.isDefaultBrowser = defaultApp.path == selfURL.path
        Log.app.debug("⏱ checkDefaultBrowserStatus: took \((CFAbsoluteTimeGetCurrent() - start) * 1000, format: .fixed(precision: 1))ms")
    }

    func setAsDefaultBrowser() {
        guard let bundleURL = Bundle.main.bundleURL as URL? else { return }
        NSWorkspace.shared.setDefaultApplication(
            at: bundleURL,
            toOpenURLsWithScheme: "http"
        ) { error in
            Task { @MainActor in
                if let error {
                    Log.app.error("Failed to set default browser (http): \(error.localizedDescription)")
                }
            }
        }
        NSWorkspace.shared.setDefaultApplication(
            at: bundleURL,
            toOpenURLsWithScheme: "https"
        ) { error in
            Task { @MainActor in
                if let error {
                    Log.app.error("Failed to set default browser (https): \(error.localizedDescription)")
                } else {
                    self.checkDefaultBrowserStatus()
                }
            }
        }
    }
}
