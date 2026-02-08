import Foundation
import Observation
import os

@Observable
@MainActor
final class AppState {
    var pendingURL: URL?
    var pendingURLTitle: String?
    var browsers: [InstalledBrowser] = []
    var apps: [InstalledApp] = []
    var lastOpenedURL: String?
    var isPickerVisible: Bool = false
    var isDefaultBrowser: Bool = false
    var focusedBrowserIndex: Int = 0

    var urlRules: [URLRule] = []

    // Settings trigger
    var shouldOpenSettings: Bool = false

    var visibleBrowsers: [InstalledBrowser] {
        browsers.filter { $0.isVisible && !$0.isIgnored }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var ignoredBrowsers: [InstalledBrowser] {
        browsers.filter(\.isIgnored).sorted { $0.sortOrder < $1.sortOrder }
    }

    var visibleApps: [InstalledApp] {
        apps.filter(\.isVisible).sorted { $0.sortOrder < $1.sortOrder }
    }

    init() {
        lastOpenedURL = SettingsStorage.shared.lastURL
        Log.app.debug("AppState initialized")
    }
}
