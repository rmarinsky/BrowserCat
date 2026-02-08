import Foundation

struct AppDefinition {
    let bundleID: String
    let displayName: String
    /// Web host patterns this app handles (e.g., ["teams.microsoft.com"])
    let hostPatterns: [String]
    /// Custom URL scheme (e.g., "msteams", "slack", "figma")
    let urlScheme: String?
    /// Optional URL converter: transforms an HTTPS URL into a deep link URL.
    /// If nil, the HTTPS URL is passed directly to the app via `open -a`.
    let convertURL: ((URL) -> URL?)?

    static let registry: [AppDefinition] = [
        // Microsoft Teams
        AppDefinition(
            bundleID: "com.microsoft.teams2",
            displayName: "Teams",
            hostPatterns: ["teams.microsoft.com", "teams.live.com"],
            urlScheme: "msteams",
            convertURL: { url in
                // https://teams.microsoft.com/... → msteams:/...
                let str = url.absoluteString
                guard str.hasPrefix("https://teams.microsoft.com") else { return nil }
                return URL(string: str.replacingOccurrences(of: "https://teams.microsoft.com", with: "msteams:"))
            }
        ),
        // Legacy Teams
        AppDefinition(
            bundleID: "com.microsoft.teams",
            displayName: "Teams (Classic)",
            hostPatterns: ["teams.microsoft.com", "teams.live.com"],
            urlScheme: "msteams",
            convertURL: { url in
                let str = url.absoluteString
                guard str.hasPrefix("https://teams.microsoft.com") else { return nil }
                return URL(string: str.replacingOccurrences(of: "https://teams.microsoft.com", with: "msteams:"))
            }
        ),
        // Slack
        AppDefinition(
            bundleID: "com.tinyspeck.slackmacgap",
            displayName: "Slack",
            hostPatterns: ["slack.com", "app.slack.com"],
            urlScheme: "slack",
            convertURL: nil // Slack handles HTTPS URLs directly
        ),
        // Discord
        AppDefinition(
            bundleID: "com.hnc.Discord",
            displayName: "Discord",
            hostPatterns: ["discord.com", "discordapp.com", "canary.discord.com", "ptb.discord.com"],
            urlScheme: "discord",
            convertURL: { url in
                // https://discord.com/channels/... → discord://-/channels/...
                let str = url.absoluteString
                if let range = str.range(of: "https://discord.com/") {
                    let path = str[range.upperBound...]
                    return URL(string: "discord://-/\(path)")
                }
                if let range = str.range(of: "https://discordapp.com/") {
                    let path = str[range.upperBound...]
                    return URL(string: "discord://-/\(path)")
                }
                return nil
            }
        ),
        // Figma
        AppDefinition(
            bundleID: "com.figma.Desktop",
            displayName: "Figma",
            hostPatterns: ["figma.com", "www.figma.com"],
            urlScheme: "figma",
            convertURL: nil // Figma handles HTTPS URLs directly
        ),
        // Figma Beta
        AppDefinition(
            bundleID: "com.figma.Desktop.beta",
            displayName: "Figma Beta",
            hostPatterns: ["figma.com", "www.figma.com"],
            urlScheme: "figma",
            convertURL: nil
        ),
        // Notion
        AppDefinition(
            bundleID: "notion.id",
            displayName: "Notion",
            hostPatterns: ["notion.so", "www.notion.so"],
            urlScheme: "notion",
            convertURL: nil
        ),
        // Spotify
        AppDefinition(
            bundleID: "com.spotify.client",
            displayName: "Spotify",
            hostPatterns: ["open.spotify.com"],
            urlScheme: "spotify",
            convertURL: nil
        ),
        // Zoom
        AppDefinition(
            bundleID: "us.zoom.xos",
            displayName: "Zoom",
            hostPatterns: ["zoom.us", "us02web.zoom.us", "us04web.zoom.us", "us05web.zoom.us", "us06web.zoom.us"],
            urlScheme: "zoommtg",
            convertURL: nil
        ),
        // Linear
        AppDefinition(
            bundleID: "com.linear",
            displayName: "Linear",
            hostPatterns: ["linear.app"],
            urlScheme: "linear",
            convertURL: nil
        ),
        // Telegram
        AppDefinition(
            bundleID: "ru.keepcoder.Telegram",
            displayName: "Telegram",
            hostPatterns: ["t.me", "telegram.me", "web.telegram.org"],
            urlScheme: "tg",
            convertURL: nil
        ),
        // Telegram (App Store version)
        AppDefinition(
            bundleID: "com.tdesktop.Telegram",
            displayName: "Telegram",
            hostPatterns: ["t.me", "telegram.me", "web.telegram.org"],
            urlScheme: "tg",
            convertURL: nil
        ),
        // WhatsApp
        AppDefinition(
            bundleID: "net.whatsapp.WhatsApp",
            displayName: "WhatsApp",
            hostPatterns: ["web.whatsapp.com", "wa.me", "api.whatsapp.com"],
            urlScheme: "whatsapp",
            convertURL: nil
        ),
        // 1Password
        AppDefinition(
            bundleID: "com.1password.1password",
            displayName: "1Password",
            hostPatterns: ["my.1password.com", "start.1password.com"],
            urlScheme: "onepassword",
            convertURL: nil
        ),
        // Visual Studio Code
        AppDefinition(
            bundleID: "com.microsoft.VSCode",
            displayName: "VS Code",
            hostPatterns: ["vscode.dev", "insiders.vscode.dev"],
            urlScheme: "vscode",
            convertURL: nil
        ),
        // Obsidian
        AppDefinition(
            bundleID: "md.obsidian",
            displayName: "Obsidian",
            hostPatterns: ["obsidian.md"],
            urlScheme: "obsidian",
            convertURL: nil
        ),
        // Jira
        AppDefinition(
            bundleID: "com.atlassian.jira",
            displayName: "Jira",
            hostPatterns: ["atlassian.net"],
            urlScheme: nil,
            convertURL: nil
        ),
        // Miro
        AppDefinition(
            bundleID: "com.electron.realtimeboard",
            displayName: "Miro",
            hostPatterns: ["miro.com"],
            urlScheme: nil,
            convertURL: nil
        ),
        // Loom
        AppDefinition(
            bundleID: "com.loom.desktop",
            displayName: "Loom",
            hostPatterns: ["loom.com", "www.loom.com"],
            urlScheme: "loom",
            convertURL: nil
        ),
    ]

    /// Registry keyed by bundleID for quick lookup
    static let registryByID: [String: AppDefinition] = {
        var dict = [String: AppDefinition]()
        for def in registry {
            if dict[def.bundleID] == nil {
                dict[def.bundleID] = def
            }
        }
        return dict
    }()
}
