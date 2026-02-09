import SwiftUI

@main
struct BrowserCatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(
                onReopenLastURL: { appDelegate.reopenLastURL() }
            )
            .environment(appDelegate.appState)
            .onChange(of: appDelegate.appState.shouldOpenSettings) { _, shouldOpen in
                if shouldOpen {
                    appDelegate.appState.shouldOpenSettings = false
                    // The app may be in .prohibited policy after the picker closes,
                    // so switch to .accessory before opening settings.
                    NSApp.setActivationPolicy(.accessory)
                    openSettings()
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        } label: {
            Image(systemName: "cat.fill")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(appDelegate: appDelegate)
                .environment(appDelegate.appState)
        }
    }
}
