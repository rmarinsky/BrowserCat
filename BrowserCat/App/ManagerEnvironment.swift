import SwiftUI

// MARK: - Environment Keys

private struct BrowserManagerKey: EnvironmentKey {
    static var defaultValue: BrowserManager { fatalError("BrowserManager not injected") }
}

private struct AppManagerKey: EnvironmentKey {
    static var defaultValue: AppManager { fatalError("AppManager not injected") }
}

private struct URLRulesManagerKey: EnvironmentKey {
    static var defaultValue: URLRulesManager { fatalError("URLRulesManager not injected") }
}

private struct DefaultBrowserManagerKey: EnvironmentKey {
    static var defaultValue: DefaultBrowserManager { fatalError("DefaultBrowserManager not injected") }
}

private struct PickerCoordinatorKey: EnvironmentKey {
    static var defaultValue: PickerCoordinator { fatalError("PickerCoordinator not injected") }
}

private struct HistoryManagerKey: EnvironmentKey {
    static var defaultValue: HistoryManager { fatalError("HistoryManager not injected") }
}

// MARK: - Environment Values

extension EnvironmentValues {
    var browserManager: BrowserManager {
        get { self[BrowserManagerKey.self] }
        set { self[BrowserManagerKey.self] = newValue }
    }

    var appManager: AppManager {
        get { self[AppManagerKey.self] }
        set { self[AppManagerKey.self] = newValue }
    }

    var urlRulesManager: URLRulesManager {
        get { self[URLRulesManagerKey.self] }
        set { self[URLRulesManagerKey.self] = newValue }
    }

    var defaultBrowserManager: DefaultBrowserManager {
        get { self[DefaultBrowserManagerKey.self] }
        set { self[DefaultBrowserManagerKey.self] = newValue }
    }

    var pickerCoordinator: PickerCoordinator {
        get { self[PickerCoordinatorKey.self] }
        set { self[PickerCoordinatorKey.self] = newValue }
    }

    var historyManager: HistoryManager {
        get { self[HistoryManagerKey.self] }
        set { self[HistoryManagerKey.self] = newValue }
    }
}
