import LaunchAtLogin
import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AppState.self) private var appState
    var appDelegate: AppDelegate

    var body: some View {
        let start = CFAbsoluteTimeGetCurrent()
        let _ = Log.settings.debug("⏱ GeneralSettingsView: body evaluation started")

        Form {
            Section("Default Browser") {
                HStack {
                    if appState.isDefaultBrowser {
                        Label("BrowserCat is the default browser", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("BrowserCat is not the default browser", systemImage: "xmark.circle")
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("Set as Default") {
                            appDelegate.setAsDefaultBrowser()
                        }
                    }
                }
            }

            Section("Startup") {
                LaunchAtLogin.Toggle("Launch at login")
            }

            Section("Browsers") {
                Button("Rescan Browsers") {
                    appDelegate.refreshBrowsers()
                }

                Text("\(appState.browsers.count) browsers detected")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

        }
        .formStyle(.grouped)
        .onAppear {
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            Log.settings.debug("⏱ GeneralSettingsView: onAppear, \(elapsed, format: .fixed(precision: 1))ms since body")

            let checkStart = CFAbsoluteTimeGetCurrent()
            appDelegate.checkDefaultBrowserStatus()
            let checkElapsed = (CFAbsoluteTimeGetCurrent() - checkStart) * 1000
            Log.settings.debug("⏱ GeneralSettingsView: checkDefaultBrowserStatus took \(checkElapsed, format: .fixed(precision: 1))ms")
        }
    }
}
