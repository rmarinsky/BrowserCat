import AppKit
import os

@MainActor
final class AppDetector {

    /// Detect installed apps from the curated AppDefinition registry.
    /// Only shows apps explicitly listed in the registry (like Browserosaurus).
    func detectApps() -> [InstalledApp] {
        var apps: [InstalledApp] = []
        var seenBundleIDs: Set<String> = []
        var index = 0

        for definition in AppDefinition.registry {
            guard seenBundleIDs.insert(definition.bundleID).inserted else { continue }

            guard let appURL = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: definition.bundleID
            ) else { continue }

            let bundle = Bundle(url: appURL)
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            icon.size = NSSize(width: 64, height: 64)
            let version = bundle?.infoDictionary?["CFBundleShortVersionString"] as? String

            let schemes = readURLSchemes(from: appURL)

            apps.append(InstalledApp(
                id: definition.bundleID,
                displayName: definition.displayName,
                appURL: appURL,
                urlSchemes: schemes.isEmpty ? [definition.urlScheme].compactMap { $0 } : schemes,
                hostPatterns: definition.hostPatterns,
                isVisible: true,
                sortOrder: index,
                icon: icon,
                version: version
            ))
            index += 1
        }

        Log.apps.info("Detected \(apps.count) apps")
        return apps
    }

    // MARK: - Private

    /// Read CFBundleURLTypes -> CFBundleURLSchemes from an app bundle
    private func readURLSchemes(from appURL: URL) -> [String] {
        guard let bundle = Bundle(url: appURL),
              let urlTypes = bundle.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]]
        else { return [] }

        var schemes: [String] = []
        for urlType in urlTypes {
            if let typeSchemes = urlType["CFBundleURLSchemes"] as? [String] {
                schemes.append(contentsOf: typeSchemes)
            }
        }
        return schemes.filter { scheme in
            let s = scheme.lowercased()
            return !["http", "https", "file", "mailto", "tel", "sms", "ftp", "ssh"].contains(s)
        }
    }
}
