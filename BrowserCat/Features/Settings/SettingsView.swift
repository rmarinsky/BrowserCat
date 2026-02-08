import SwiftUI

struct SettingsView: View {
    var appDelegate: AppDelegate

    var body: some View {
        let start = CFAbsoluteTimeGetCurrent()
        let _ = Log.settings.debug("⏱ SettingsView: body evaluation started")

        TabView {
            GeneralSettingsView(appDelegate: appDelegate)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppsSettingsView(appDelegate: appDelegate)
                .tabItem {
                    Label("Apps", systemImage: "square.grid.2x2")
                }

            RulesSettingsView(appDelegate: appDelegate)
                .tabItem {
                    Label("Rules", systemImage: "arrow.triangle.branch")
                }
        }
        .frame(width: 450, height: 550)
        .onAppear {
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            Log.settings.debug("⏱ SettingsView: onAppear, \(elapsed, format: .fixed(precision: 1))ms since body")
        }
    }
}
