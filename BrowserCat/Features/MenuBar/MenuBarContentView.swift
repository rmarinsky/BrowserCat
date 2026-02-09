import SwiftUI

struct MenuBarContentView: View {
    @Environment(AppState.self) private var appState
    var onReopenURL: (String) -> Void

    private var recentEntries: [HistoryEntry] {
        let seen = NSMutableOrderedSet()
        var unique: [HistoryEntry] = []
        for entry in appState.history {
            if seen.contains(entry.url) { continue }
            seen.add(entry.url)
            unique.append(entry)
            if unique.count >= appState.recentLinksCount { break }
        }
        return unique
    }

    private var todayEntries: [HistoryEntry] {
        let calendar = Calendar.current
        return appState.history.filter { calendar.isDateInToday($0.openedAt) }
    }

    var body: some View {
        Group {
            if recentEntries.isEmpty {
                Text("No recent URLs")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentEntries) { entry in
                    Button {
                        onReopenURL(entry.url)
                    } label: {
                        Label(shortenURL(entry.url), systemImage: iconForURL(entry.url))
                    }
                }
            }

            Divider()

            Menu("History") {
                if todayEntries.isEmpty {
                    Text("No links today")
                } else {
                    ForEach(todayEntries) { entry in
                        Button {
                            onReopenURL(entry.url)
                        } label: {
                            Label(
                                "\(shortenURL(entry.url)) — \(entry.appName)",
                                systemImage: iconForURL(entry.url)
                            )
                        }
                    }
                }

                Divider()

                SettingsLink {
                    Text("Open History...")
                }
            }

            Divider()

            SettingsLink {
                Text("Settings...")
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit BrowserCat") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("Q", modifiers: .command)
        }
    }

    private func shortenURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString) else { return urlString }
        let host = url.host() ?? urlString
        if host.count > 30 {
            return String(host.prefix(27)) + "..."
        }
        return host
    }

    private static let domainIcons: [(pattern: String, icon: String)] = [
        ("github", "chevron.left.forwardslash.chevron.right"),
        ("gitlab", "chevron.left.forwardslash.chevron.right"),
        ("bitbucket", "chevron.left.forwardslash.chevron.right"),
        ("linkedin", "briefcase"),
        ("google", "magnifyingglass"),
        ("youtube", "play.rectangle"),
        ("slack", "number"),
        ("discord", "bubble.left.and.bubble.right"),
        ("teams.microsoft", "person.3"),
        ("zoom", "video"),
        ("figma", "paintbrush"),
        ("notion", "doc.text"),
        ("spotify", "music.note"),
        ("telegram", "paperplane"),
        ("t.me", "paperplane"),
        ("whatsapp", "phone.bubble"),
        ("stackoverflow", "questionmark.circle"),
        ("reddit", "text.bubble"),
        ("medium", "book"),
        ("twitter", "at"),
        ("x.com", "at"),
        ("jira", "checklist"),
        ("confluence", "doc.richtext"),
        ("linear", "circle.dotted"),
        ("miro", "rectangle.on.rectangle"),
        ("loom", "video.bubble"),
        ("mono", "banknote"),
        ("apple", "apple.logo"),
    ]

    private func iconForURL(_ urlString: String) -> String {
        guard let host = URL(string: urlString)?.host?.lowercased() else { return "globe" }
        for entry in Self.domainIcons {
            if host.contains(entry.pattern) { return entry.icon }
        }
        return "globe"
    }
}
