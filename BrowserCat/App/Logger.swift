import Foundation
import os

enum Log {
    static let app = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BrowserCat", category: "app")
    static let browser = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BrowserCat", category: "browser")
    static let picker = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BrowserCat", category: "picker")
    static let settings = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BrowserCat", category: "settings")
    static let profiles = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BrowserCat", category: "profiles")
    static let rules = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BrowserCat", category: "rules")
    static let apps = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BrowserCat", category: "apps")
    static let history = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BrowserCat", category: "history")
}
