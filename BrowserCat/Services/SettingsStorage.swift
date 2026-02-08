import Foundation
import os

final class SettingsStorage {
    static let shared = SettingsStorage()

    private let defaults = UserDefaults.standard
    private let fileManager = FileManager.default

    private var configDir: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("BrowserCat")
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var configURL: URL {
        configDir.appendingPathComponent("browsers.json")
    }

    private var rulesURL: URL {
        configDir.appendingPathComponent("rules.json")
    }

    private var appsURL: URL {
        configDir.appendingPathComponent("apps.json")
    }

    // MARK: - Simple values

    var lastURL: String? {
        get { defaults.string(forKey: "lastURL") }
        set { defaults.set(newValue, forKey: "lastURL") }
    }

    // MARK: - Browser config persistence

    func saveBrowserConfigs(_ browsers: [InstalledBrowser]) {
        // Deduplicate by ID, keeping first occurrence
        var seen = Set<String>()
        let configs = browsers.compactMap { browser -> BrowserConfig? in
            guard seen.insert(browser.id).inserted else { return nil }
            return BrowserConfig(from: browser)
        }
        do {
            let data = try JSONEncoder().encode(configs)
            try data.write(to: configURL, options: .atomic)
            Log.settings.debug("Saved \(configs.count) browser configs")
        } catch {
            Log.settings.error("Failed to save browser configs: \(error.localizedDescription)")
        }
    }

    func loadBrowserConfigs() -> [BrowserConfig]? {
        guard fileManager.fileExists(atPath: configURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: configURL)
            let configs = try JSONDecoder().decode([BrowserConfig].self, from: data)
            Log.settings.debug("Loaded \(configs.count) browser configs")
            return configs
        } catch {
            Log.settings.error("Failed to load browser configs: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - URL Rules persistence

    func saveURLRules(_ rules: [URLRule]) {
        do {
            let data = try JSONEncoder().encode(rules)
            try data.write(to: rulesURL, options: .atomic)
            Log.settings.debug("Saved \(rules.count) URL rules")
        } catch {
            Log.settings.error("Failed to save URL rules: \(error.localizedDescription)")
        }
    }

    func loadURLRules() -> [URLRule] {
        guard fileManager.fileExists(atPath: rulesURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: rulesURL)
            let rules = try JSONDecoder().decode([URLRule].self, from: data)
            Log.settings.debug("Loaded \(rules.count) URL rules")
            return rules
        } catch {
            Log.settings.error("Failed to load URL rules: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - App config persistence

    func saveAppConfigs(_ apps: [InstalledApp]) {
        var seen = Set<String>()
        let configs = apps.compactMap { app -> AppConfig? in
            guard seen.insert(app.id).inserted else { return nil }
            return AppConfig(from: app)
        }
        do {
            let data = try JSONEncoder().encode(configs)
            try data.write(to: appsURL, options: .atomic)
            Log.settings.debug("Saved \(configs.count) app configs")
        } catch {
            Log.settings.error("Failed to save app configs: \(error.localizedDescription)")
        }
    }

    func loadAppConfigs() -> [AppConfig]? {
        guard fileManager.fileExists(atPath: appsURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: appsURL)
            let configs = try JSONDecoder().decode([AppConfig].self, from: data)
            Log.settings.debug("Loaded \(configs.count) app configs")
            return configs
        } catch {
            Log.settings.error("Failed to load app configs: \(error.localizedDescription)")
            return nil
        }
    }
}
