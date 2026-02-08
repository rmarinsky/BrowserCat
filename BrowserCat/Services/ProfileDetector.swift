import Foundation
import os

@MainActor
final class ProfileDetector {
    private let fileManager = FileManager.default

    func detectProfiles(for browser: InstalledBrowser) -> [BrowserProfile] {
        guard let profileType = browser.profileType,
              let profileDataPath = browser.profileDataPath
        else {
            return []
        }

        let profiles: [BrowserProfile]
        switch profileType {
        case .chromium:
            profiles = detectChromiumProfiles(dataPath: profileDataPath)
        case .firefox:
            profiles = detectFirefoxProfiles(dataPath: profileDataPath)
        }

        if !profiles.isEmpty {
            Log.profiles.info("Detected \(profiles.count) profiles for \(browser.displayName)")
        }
        return profiles
    }

    // MARK: - Chromium

    private func detectChromiumProfiles(dataPath: String) -> [BrowserProfile] {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let localStatePath = appSupport
            .appendingPathComponent(dataPath)
            .appendingPathComponent("Local State")

        guard let data = try? Data(contentsOf: localStatePath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profile = json["profile"] as? [String: Any],
              let infoCache = profile["info_cache"] as? [String: Any]
        else {
            Log.profiles.debug("No Chromium Local State found at \(localStatePath.path)")
            return []
        }

        var profiles: [BrowserProfile] = []
        for (dirName, value) in infoCache {
            guard let info = value as? [String: Any] else { continue }
            let name = info["name"] as? String ?? dirName
            let email = info["user_name"] as? String
            let displayEmail = (email?.isEmpty == true) ? nil : email
            profiles.append(BrowserProfile(
                directoryName: dirName,
                displayName: name,
                email: displayEmail
            ))
        }

        return profiles.sorted { $0.directoryName < $1.directoryName }
    }

    // MARK: - Firefox

    private func detectFirefoxProfiles(dataPath: String) -> [BrowserProfile] {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let profilesIniPath = appSupport
            .appendingPathComponent(dataPath)
            .appendingPathComponent("profiles.ini")

        guard let content = try? String(contentsOf: profilesIniPath, encoding: .utf8) else {
            Log.profiles.debug("No Firefox profiles.ini found at \(profilesIniPath.path)")
            return []
        }

        var profiles: [BrowserProfile] = []
        var currentName: String?
        var currentPath: String?

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[Profile") || trimmed.hasPrefix("[Install") {
                // Save previous profile
                if let name = currentName, let path = currentPath {
                    let dirName = URL(fileURLWithPath: path).lastPathComponent
                    profiles.append(BrowserProfile(
                        directoryName: dirName,
                        displayName: name,
                        email: nil
                    ))
                }
                currentName = nil
                currentPath = nil
                continue
            }

            if trimmed.hasPrefix("Name=") {
                currentName = String(trimmed.dropFirst(5))
            } else if trimmed.hasPrefix("Path=") {
                currentPath = String(trimmed.dropFirst(5))
            }
        }

        // Last profile
        if let name = currentName, let path = currentPath {
            let dirName = URL(fileURLWithPath: path).lastPathComponent
            profiles.append(BrowserProfile(
                directoryName: dirName,
                displayName: name,
                email: nil
            ))
        }

        return profiles
    }
}
