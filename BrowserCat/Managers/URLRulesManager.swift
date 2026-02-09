import Foundation
import os

@MainActor
final class URLRulesManager {
    private let urlRuleMatcher = URLRuleMatcher()

    func load(into state: AppState) {
        state.urlRules = SettingsStorage.shared.loadURLRules()
    }

    func save(_ rules: [URLRule]) {
        SettingsStorage.shared.saveURLRules(rules)
    }

    func findMatch(for url: URL, browsers: [InstalledBrowser], apps: [InstalledApp], rules: [URLRule]) -> URLRuleMatch? {
        guard let rule = urlRuleMatcher.findMatchingRule(for: url, rules: rules) else {
            return nil
        }

        switch rule.targetType {
        case .browser:
            if let browser = browsers.first(where: { $0.id == rule.browserID }) {
                let profile = rule.profileDirectoryName.flatMap { dirName in
                    browser.profiles.first { $0.directoryName == dirName }
                }
                return .browser(browser, profile: profile)
            }
        case .app:
            if let app = apps.first(where: { $0.id == rule.browserID }) {
                return .app(app)
            }
        }

        return nil
    }
}

enum URLRuleMatch {
    case browser(InstalledBrowser, profile: BrowserProfile?)
    case app(InstalledApp)
}
