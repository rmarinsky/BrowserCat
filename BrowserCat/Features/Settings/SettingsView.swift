import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppsSettingsView()
                .tabItem {
                    Label("Apps", systemImage: "square.grid.2x2")
                }

            RulesSettingsView()
                .tabItem {
                    Label("Rules", systemImage: "arrow.triangle.branch")
                }

            HistorySettingsView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 550)
    }
}
