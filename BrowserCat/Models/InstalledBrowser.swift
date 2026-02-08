import AppKit
import Foundation

struct InstalledBrowser: Identifiable, Equatable {
    let id: String // bundleID
    var displayName: String
    var appURL: URL
    var isVisible: Bool
    var isIgnored: Bool = false
    var hotkey: Character?
    var sortOrder: Int
    var supportsPrivateMode: Bool
    var privateModeArgs: [String]?
    var profileDataPath: String?
    var profileType: ProfileType?
    var profiles: [BrowserProfile] = []

    // Non-codable, loaded at runtime
    var icon: NSImage?
    var version: String?

    var hasProfiles: Bool { profiles.count > 1 }

    static func == (lhs: InstalledBrowser, rhs: InstalledBrowser) -> Bool {
        lhs.id == rhs.id
            && lhs.displayName == rhs.displayName
            && lhs.appURL == rhs.appURL
            && lhs.isVisible == rhs.isVisible
            && lhs.isIgnored == rhs.isIgnored
            && lhs.hotkey == rhs.hotkey
            && lhs.sortOrder == rhs.sortOrder
            && lhs.supportsPrivateMode == rhs.supportsPrivateMode
            && lhs.profiles == rhs.profiles
    }
}

// MARK: - Codable support (without icon)

struct BrowserConfig: Codable {
    let id: String
    var displayName: String
    var isVisible: Bool
    var isIgnored: Bool
    var hotkey: String? // Store Character as String
    var sortOrder: Int
    var profileHotkeys: [String: String]? // directoryName -> hotkey character

    init(from browser: InstalledBrowser) {
        id = browser.id
        displayName = browser.displayName
        isVisible = browser.isVisible
        isIgnored = browser.isIgnored
        hotkey = browser.hotkey.map { String($0) }
        sortOrder = browser.sortOrder

        let keys = browser.profiles.compactMap { profile -> (String, String)? in
            guard let key = profile.hotkey else { return nil }
            return (profile.directoryName, String(key))
        }
        profileHotkeys = keys.isEmpty ? nil : Dictionary(keys, uniquingKeysWith: { first, _ in first })
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        isIgnored = try container.decodeIfPresent(Bool.self, forKey: .isIgnored) ?? false
        hotkey = try container.decodeIfPresent(String.self, forKey: .hotkey)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        profileHotkeys = try container.decodeIfPresent([String: String].self, forKey: .profileHotkeys)
    }
}
