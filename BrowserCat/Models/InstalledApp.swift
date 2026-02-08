import AppKit
import Foundation

struct InstalledApp: Identifiable, Equatable {
    let id: String // bundleID
    var displayName: String
    var appURL: URL
    /// Custom URL schemes this app handles (e.g., ["slack", "slack-beta"])
    var urlSchemes: [String]
    /// Web host patterns this app can open (from AppDefinition registry)
    var hostPatterns: [String]
    var isVisible: Bool
    var sortOrder: Int
    var hotkey: Character?

    // Non-codable, loaded at runtime
    var icon: NSImage?
    var version: String?

    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.id == rhs.id
            && lhs.displayName == rhs.displayName
            && lhs.appURL == rhs.appURL
            && lhs.urlSchemes == rhs.urlSchemes
            && lhs.hostPatterns == rhs.hostPatterns
            && lhs.isVisible == rhs.isVisible
            && lhs.sortOrder == rhs.sortOrder
            && lhs.hotkey == rhs.hotkey
    }

    /// Check if this app handles the given URL based on host patterns
    func matchesHost(of url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return hostPatterns.contains { pattern in
            let p = pattern.lowercased()
            return host == p || host.hasSuffix(".\(p)")
        }
    }
}

// MARK: - Codable support (without icon)

struct AppConfig: Codable {
    let id: String
    var displayName: String
    var isVisible: Bool
    var hotkey: String?
    var sortOrder: Int

    init(from app: InstalledApp) {
        id = app.id
        displayName = app.displayName
        isVisible = app.isVisible
        hotkey = app.hotkey.map { String($0) }
        sortOrder = app.sortOrder
    }
}
