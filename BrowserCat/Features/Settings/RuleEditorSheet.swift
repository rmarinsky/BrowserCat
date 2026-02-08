import SwiftUI

struct RuleEditorSheet: View {
    @State var rule: URLRule
    let browsers: [InstalledBrowser]
    let apps: [InstalledApp]
    let onSave: (URLRule) -> Void
    let onCancel: () -> Void

    private var selectedBrowser: InstalledBrowser? {
        browsers.first { $0.id == rule.browserID }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("URL Rule")
                .font(.headline)

            Form {
                // Pattern
                TextField("Pattern", text: $rule.pattern)
                    .textFieldStyle(.roundedBorder)

                // Match type
                Picker("Match Type", selection: $rule.matchType) {
                    ForEach(URLRule.MatchType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                // Target type
                Picker("Open In", selection: $rule.targetType) {
                    ForEach(URLRule.TargetType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .onChange(of: rule.targetType) {
                    // Reset selection when switching target type
                    rule.browserID = ""
                    rule.profileDirectoryName = nil
                }

                // Browser or App selection
                switch rule.targetType {
                case .browser:
                    Picker("Browser", selection: $rule.browserID) {
                        Text("Select...").tag("")
                        ForEach(browsers) { browser in
                            Text(browser.displayName).tag(browser.id)
                        }
                    }

                    // Profile
                    if let browser = selectedBrowser, browser.hasProfiles {
                        Picker("Profile", selection: profileBinding) {
                            Text("Any Profile").tag(String?.none)
                            ForEach(browser.profiles) { profile in
                                Text(profileLabel(profile)).tag(Optional(profile.directoryName))
                            }
                        }
                    }

                case .app:
                    Picker("App", selection: $rule.browserID) {
                        Text("Select...").tag("")
                        ForEach(apps) { app in
                            Text(app.displayName).tag(app.id)
                        }
                    }
                }

                // Enabled
                Toggle("Enabled", isOn: $rule.isEnabled)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    onSave(rule)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(rule.pattern.isEmpty || rule.browserID.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 380)
    }

    private var profileBinding: Binding<String?> {
        Binding(
            get: { rule.profileDirectoryName },
            set: { rule.profileDirectoryName = $0 }
        )
    }

    private func profileLabel(_ profile: BrowserProfile) -> String {
        if let email = profile.email {
            return "\(profile.displayName) (\(email))"
        }
        return profile.displayName
    }
}
