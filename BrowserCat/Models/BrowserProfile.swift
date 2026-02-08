import Foundation

struct BrowserProfile: Identifiable, Codable, Equatable, Hashable {
    let directoryName: String // "Default", "Profile 1" (Chromium) or profile name (Firefox)
    let displayName: String // "Roma", "travisperkins.co.uk"
    let email: String? // "newromka@gmail.com" or nil
    var hotkey: Character?

    var id: String { directoryName }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case directoryName, displayName, email, hotkey
    }

    init(directoryName: String, displayName: String, email: String?, hotkey: Character? = nil) {
        self.directoryName = directoryName
        self.displayName = displayName
        self.email = email
        self.hotkey = hotkey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        directoryName = try container.decode(String.self, forKey: .directoryName)
        displayName = try container.decode(String.self, forKey: .displayName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        let hotkeyStr = try container.decodeIfPresent(String.self, forKey: .hotkey)
        hotkey = hotkeyStr?.first
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(directoryName, forKey: .directoryName)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(hotkey.map { String($0) }, forKey: .hotkey)
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(directoryName)
    }

    // MARK: - Equatable

    static func == (lhs: BrowserProfile, rhs: BrowserProfile) -> Bool {
        lhs.directoryName == rhs.directoryName
            && lhs.displayName == rhs.displayName
            && lhs.email == rhs.email
            && lhs.hotkey == rhs.hotkey
    }
}
