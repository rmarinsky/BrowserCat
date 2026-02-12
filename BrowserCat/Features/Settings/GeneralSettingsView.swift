import LaunchAtLogin
import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.defaultBrowserManager) private var defaultBrowserManager

    var body: some View {
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
                            defaultBrowserManager?.setAsDefault(state: appState)
                        }
                    }
                }
            }

            Section("Startup") {
                LaunchAtLogin.Toggle("Launch at login")
            }

            Section("Picker") {
                Toggle("Compact view", isOn: Binding(
                    get: { appState.compactPickerView },
                    set: { newValue in
                        appState.compactPickerView = newValue
                        SettingsStorage.shared.compactPickerView = newValue
                    }
                ))
            }

            Section("Menu Bar") {
                Picker("Recent links", selection: Binding(
                    get: { appState.recentLinksCount },
                    set: { newValue in
                        appState.recentLinksCount = newValue
                        SettingsStorage.shared.recentLinksCount = newValue
                    }
                )) {
                    ForEach(1...5, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
            }

            Section("Developer") {
                LabeledContent("Made by") {
                    Text("Roman Marinsky \u{1F1FA}\u{1F1E6}")
                }
            }

        }
        .formStyle(.grouped)
        .onAppear {
            defaultBrowserManager?.checkIsDefault(state: appState)
        }
    }
}
