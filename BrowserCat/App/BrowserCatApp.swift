import SwiftUI

@main
struct BrowserCatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(
                onReopenURL: { urlString in appDelegate.pickerCoordinator.reopenURL(urlString, state: appDelegate.appState) }
            )
            .environment(appDelegate.appState)
        } label: {
            Image(systemName: "cat.fill")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environment(appDelegate.appState)
                .environment(\.browserManager, appDelegate.browserManager)
                .environment(\.appManager, appDelegate.appManager)
                .environment(\.urlRulesManager, appDelegate.urlRulesManager)
                .environment(\.defaultBrowserManager, appDelegate.defaultBrowserManager)
                .environment(\.pickerCoordinator, appDelegate.pickerCoordinator)
                .environment(\.historyManager, appDelegate.historyManager)
        }
    }
}
