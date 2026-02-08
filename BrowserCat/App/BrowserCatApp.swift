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
                    let start = CFAbsoluteTimeGetCurrent()
                    Log.settings.debug("⏱ Settings: openSettings() called")
                    openSettings()
                    let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
                    Log.settings.debug("⏱ Settings: openSettings() returned in \(elapsed, format: .fixed(precision: 1))ms")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NSApp.activate(ignoringOtherApps: true)
                        let total = (CFAbsoluteTimeGetCurrent() - start) * 1000
                        Log.settings.debug("⏱ Settings: NSApp.activate completed, total \(total, format: .fixed(precision: 1))ms since open")
                    }
                    appDelegate.appState.shouldOpenSettings = false
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
