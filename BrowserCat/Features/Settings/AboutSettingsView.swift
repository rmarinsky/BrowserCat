import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 64, height: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("BrowserCat")
                            .font(.title2.bold())

                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("macOS browser picker")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Developer") {
                LabeledContent("Made by") {
                    Text("Roman Marinsky 🇺🇦")
                }

                LabeledContent("") {
                    Text("Made in Ukraine with ❤️")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Link(destination: URL(string: "https://rmarinsky.com.ua")!) {
                    LabeledContent("Website") {
                        HStack(spacing: 4) {
                            Text("rmarinsky.com.ua")
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                        .foregroundStyle(.link)
                    }
                }

                Link(destination: URL(string: "https://github.com/rmarinsky")!) {
                    LabeledContent("GitHub") {
                        HStack(spacing: 4) {
                            Text("@rmarinsky")
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                        .foregroundStyle(.link)
                    }
                }

                Link(destination: URL(string: "https://linkedin.com/in/rmarinsky")!) {
                    LabeledContent("LinkedIn") {
                        HStack(spacing: 4) {
                            Text("in/rmarinsky")
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                        .foregroundStyle(.link)
                    }
                }
            }

            Section {
                Link(destination: URL(string: "https://base.monobank.ua/3yGFDUvCLJuNhm#subscriptions")!) {
                    HStack {
                        Text("💛 Support the Developer")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                    .foregroundStyle(.link)
                }
            }

            Section("Project") {
                Link(destination: URL(string: "https://github.com/rmarinsky/BrowserCat")!) {
                    LabeledContent("Source Code") {
                        HStack(spacing: 4) {
                            Text("rmarinsky/BrowserCat")
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                        .foregroundStyle(.link)
                    }
                }

                LabeledContent("License") {
                    Text("MIT")
                }
            }
        }
        .formStyle(.grouped)
    }
}
