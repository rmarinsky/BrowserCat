import AppKit
import os

@MainActor
final class DefaultBrowserManager {
    func checkIsDefault(state: AppState) {
        guard let httpURL = URL(string: "https://example.com"),
              let defaultApp = NSWorkspace.shared.urlForApplication(toOpen: httpURL),
              let selfURL = Bundle.main.bundleURL as URL?
        else {
            state.isDefaultBrowser = false
            return
        }
        state.isDefaultBrowser = defaultApp.path == selfURL.path
    }

    func setAsDefault(state: AppState) {
        guard let bundleURL = Bundle.main.bundleURL as URL? else { return }
        NSWorkspace.shared.setDefaultApplication(
            at: bundleURL,
            toOpenURLsWithScheme: "http"
        ) { error in
            Task { @MainActor in
                if let error {
                    Log.app.error("Failed to set default browser (http): \(error.localizedDescription)")
                }
            }
        }
        NSWorkspace.shared.setDefaultApplication(
            at: bundleURL,
            toOpenURLsWithScheme: "https"
        ) { error in
            Task { @MainActor in
                if let error {
                    Log.app.error("Failed to set default browser (https): \(error.localizedDescription)")
                } else {
                    self.checkIsDefault(state: state)
                }
            }
        }
    }
}
