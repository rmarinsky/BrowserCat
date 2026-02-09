import AppKit
import SwiftUI

// Borderless NSPanel returns false for canBecomeKey by default,
// which prevents keyboard and mouse input. Override to allow it.
private class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

@MainActor
final class PickerWindowController: NSObject {
    private var panel: NSPanel?
    private weak var appState: AppState?
    private weak var delegate: AppDelegate?
    private var clickMonitor: Any?
    private var keyMonitor: Any?

    init(appState: AppState, delegate: AppDelegate) {
        self.appState = appState
        self.delegate = delegate
    }

    func show() {
        let panel = makePanel()
        self.panel = panel

        let hostingView = NSHostingView(
            rootView: PickerView(appDelegate: delegate!)
                .environment(appState!)
        )
        hostingView.autoresizingMask = [.width, .height]
        hostingView.frame = panel.contentView!.bounds
        // Keep hosting view background transparent so vibrancy shows through
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        panel.contentView?.addSubview(hostingView)

        positionNearCursor(panel)

        // Activate the app so macOS delivers key/mouse events to the panel.
        // Use .accessory policy to avoid showing a dock icon.
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)

        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(hostingView)

        // Dismiss on click outside
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }

        // Handle keyboard events via local monitor since SwiftUI's
        // .onKeyPress does not work reliably inside an NSPanel.
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handleKeyEvent(event) ? nil : event
        }

        Log.picker.debug("Picker shown")
    }

    func close() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        panel?.orderOut(nil)
        panel = nil
        NSApp.setActivationPolicy(.prohibited)
        appState?.isPickerVisible = false
        delegate?.appState.pendingURL = nil
        Log.picker.debug("Picker dismissed")
    }

    // MARK: - Key Handling

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard let appState, let delegate else { return false }

        let browsers = appState.visibleBrowsers
        let allApps = appState.visibleApps
        let items = PickerItem.buildItems(browsers: browsers, apps: allApps)

        switch Int(event.keyCode) {
        case 53: // Escape
            delegate.dismissPicker()
            return true
        case 36: // Return
            if items.indices.contains(appState.focusedBrowserIndex) {
                let item = items[appState.focusedBrowserIndex]
                if let app = item.app {
                    delegate.openURL(with: app)
                } else if let browser = item.browser {
                    delegate.openURL(with: browser, mode: .normal, profile: item.profile)
                }
            }
            return true
        case 123: // Left arrow
            moveFocus(-1, itemCount: items.count)
            return true
        case 124: // Right arrow
            moveFocus(1, itemCount: items.count)
            return true
        case 125: // Down arrow
            moveFocus(columnsCount, itemCount: items.count)
            return true
        case 126: // Up arrow
            moveFocus(-columnsCount, itemCount: items.count)
            return true
        default:
            guard let keyChar = event.charactersIgnoringModifiers?.lowercased().first else { return false }
            let isPrivate = event.modifierFlags.contains(.option) || event.modifierFlags.contains(.shift)
            let mode: BrowserLauncher.OpenMode = isPrivate ? .privateMode : .normal

            // Check app hotkeys first — apps always open in normal mode
            // (Option/Shift modifier is ignored for native apps)
            for app in allApps {
                if let hotkey = app.hotkey,
                   Character(String(hotkey).lowercased()) == keyChar
                {
                    delegate.openURL(with: app)
                    return true
                }
            }

            // Check profile hotkeys (more specific)
            for browser in browsers {
                if let profile = browser.profiles.first(where: { p in
                    guard let hotkey = p.hotkey else { return false }
                    return Character(String(hotkey).lowercased()) == keyChar
                }) {
                    delegate.openURL(with: browser, mode: mode, profile: profile)
                    return true
                }
            }

            // Then check browser hotkeys
            if let index = browsers.firstIndex(where: { browser in
                guard let hotkey = browser.hotkey else { return false }
                return Character(String(hotkey).lowercased()) == keyChar
            }) {
                delegate.openURL(with: browsers[index], mode: mode)
                return true
            }
            return false
        }
    }

    private var columnsCount: Int {
        max(1, Int(380 - 24) / 80)
    }

    private func moveFocus(_ delta: Int, itemCount: Int) {
        guard let appState else { return }
        let newIndex = appState.focusedBrowserIndex + delta
        if newIndex >= 0 && newIndex < itemCount {
            appState.focusedBrowserIndex = newIndex
        }
    }

    // MARK: - Panel

    private func makePanel() -> NSPanel {
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 300),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false

        // Use NSVisualEffectView as the content view for proper vibrancy
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 380, height: 300))
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true
        panel.contentView = visualEffect

        panel.delegate = self

        return panel
    }

    private func positionNearCursor(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let panelSize = panel.frame.size

        // Find the screen that contains the mouse
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]

        let visibleFrame = screen.visibleFrame

        // Position centered on cursor, shifted up slightly
        var origin = NSPoint(
            x: mouseLocation.x - panelSize.width / 2,
            y: mouseLocation.y - panelSize.height / 2 + 40
        )

        // Clamp to screen edges
        origin.x = max(visibleFrame.minX + 8, min(origin.x, visibleFrame.maxX - panelSize.width - 8))
        origin.y = max(visibleFrame.minY + 8, min(origin.y, visibleFrame.maxY - panelSize.height - 8))

        panel.setFrameOrigin(origin)
    }
}

// MARK: - NSWindowDelegate

extension PickerWindowController: NSWindowDelegate {
    nonisolated func windowDidResignKey(_: Notification) {
        Task { @MainActor in
            close()
        }
    }
}
