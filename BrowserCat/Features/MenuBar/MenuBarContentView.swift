import SwiftUI

struct MenuBarContentView: View {
    @Environment(AppState.self) private var appState
    var onReopenLastURL: () -> Void

    var body: some View {
        Group {
            if let lastURL = appState.lastOpenedURL {
                Button("Reopen: \(shortenURL(lastURL))") {
                    onReopenLastURL()
                }
                .keyboardShortcut("L", modifiers: [.command, .shift])
            } else {
                Text("No recent URL")
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Settings...") {
                appState.shouldOpenSettings = true
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
}
