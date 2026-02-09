import Pow
import SwiftUI

struct AppsSettingsView: View {
    @Environment(AppState.self) private var appState
    var appDelegate: AppDelegate

    @State private var hotkeyTarget: String? // "browserID" or "browserID:profileDir"
    @State private var showIgnored: Bool = false
    @State private var clearedTarget: String? = nil

    private var activeBrowsers: [InstalledBrowser] {
        appState.browsers.filter { !$0.isIgnored }
    }

    var body: some View {
        let start = CFAbsoluteTimeGetCurrent()
        let _ = Log.settings.debug("⏱ AppsSettingsView: body evaluation started, \(appState.browsers.count) browsers, \(activeBrowsers.count) active")

        @Bindable var state = appState

        ScrollView {
            VStack(spacing: 0) {
                ForEach(activeBrowsers) { browser in
                    let index = state.browsers.firstIndex(where: { $0.id == browser.id })!

                    VStack(spacing: 0) {
                        browserRow(browser: browser, index: index)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)

                        // Profiles
                        if browser.hasProfiles {
                            ForEach(Array(browser.profiles.enumerated()), id: \.element.id) { profileIdx, profile in
                                Divider()
                                    .padding(.leading, 56)

                                profileRow(
                                    profile: profile,
                                    browserIndex: index,
                                    profileIndex: profileIdx
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .movingParts.move(edge: .leading),
                            removal: .movingParts.move(edge: .trailing)
                        )
                    )
                    .contextMenu {
                        Button("Ignore") {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                state.browsers[index].isIgnored = true
                                appDelegate.saveBrowserConfig()
                            }
                        }
                    }

                    Divider()
                }

                // Ignored section
                if !state.ignoredBrowsers.isEmpty {
                    Divider()

                    DisclosureGroup(isExpanded: $showIgnored) {
                        VStack(spacing: 0) {
                            ForEach(state.ignoredBrowsers) { browser in
                                HStack(spacing: 12) {
                                    if let icon = browser.icon {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 22, height: 22)
                                    } else {
                                        Image(systemName: "globe")
                                            .font(.system(size: 16))
                                            .frame(width: 22, height: 22)
                                    }

                                    Text(browser.displayName)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    Button("Restore") {
                                        if let idx = state.browsers.firstIndex(where: { $0.id == browser.id }) {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                state.browsers[idx].isIgnored = false
                                                appDelegate.saveBrowserConfig()
                                            }
                                        }
                                    }
                                    .controlSize(.small)
                                }
                                .padding(.vertical, 4)
                                .transition(.movingParts.blur)
                            }
                        }
                        .padding(.horizontal, 16)
                    } label: {
                        Text("Ignored (\(state.ignoredBrowsers.count))")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showIgnored)
                }

                // Native Apps section
                if !state.apps.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Native Apps")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)

                        ForEach(state.apps) { app in
                            let appIndex = state.apps.firstIndex(where: { $0.id == app.id })!

                            HStack(spacing: 12) {
                                if let icon = app.icon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                } else {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 24))
                                        .frame(width: 32, height: 32)
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(app.displayName)
                                        .font(.system(size: 13, weight: .medium))
                                    if let version = app.version {
                                        Text(version)
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                // Hotkey
                                hotkeyButton(
                                    hotkey: app.hotkey,
                                    targetID: "app:\(app.id)"
                                )

                                // Visibility toggle
                                Toggle("", isOn: Binding(
                                    get: { app.isVisible },
                                    set: { newValue in
                                        appState.apps[appIndex].isVisible = newValue
                                        appDelegate.saveAppConfig()
                                    }
                                ))
                                .toggleStyle(.switch)
                                .controlSize(.mini)
                                .labelsHidden()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)

                            Divider()
                        }
                    }
                }

                // Rescan button
                Divider()

                Button {
                    appDelegate.refreshBrowsers()
                    appDelegate.refreshApps()
                } label: {
                    Label("Rescan Apps", systemImage: "arrow.clockwise")
                }
                .padding(16)
            }
        }
        .onAppear {
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            Log.settings.debug("⏱ AppsSettingsView: onAppear, \(elapsed, format: .fixed(precision: 1))ms since body")
        }
    }

    // MARK: - Browser Row

    @ViewBuilder
    private func browserRow(browser: InstalledBrowser, index: Int) -> some View {
        HStack(spacing: 12) {
            // Icon
            if let icon = browser.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 24))
                    .frame(width: 32, height: 32)
            }

            // Name + version
            VStack(alignment: .leading, spacing: 1) {
                Text(browser.displayName)
                    .font(.system(size: 13, weight: .medium))
                if let version = browser.version {
                    Text(version)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Hotkey
            hotkeyButton(
                hotkey: browser.hotkey,
                targetID: browser.id
            )

            // Visibility toggle
            Toggle("", isOn: Binding(
                get: { browser.isVisible },
                set: { newValue in
                    appState.browsers[index].isVisible = newValue
                    appDelegate.saveBrowserConfig()
                }
            ))
            .toggleStyle(.switch)
            .controlSize(.mini)
            .labelsHidden()
        }
    }

    // MARK: - Profile Row

    @ViewBuilder
    private func profileRow(profile: BrowserProfile, browserIndex: Int, profileIndex: Int) -> some View {
        HStack(spacing: 12) {
            // Avatar in a 32pt frame to match browser icon width
            profileAvatar(for: profile)
                .frame(width: 32, height: 32)

            // Name + email
            VStack(alignment: .leading, spacing: 1) {
                Text(profile.displayName)
                    .font(.system(size: 12))
                if let email = profile.email {
                    Text(email)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Profile hotkey
            hotkeyButton(
                hotkey: profile.hotkey,
                targetID: "\(appState.browsers[browserIndex].id):\(profile.directoryName)"
            )

            // Invisible toggle placeholder to align with browser row
            Toggle("", isOn: .constant(true))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .hidden()
        }
    }

    // MARK: - Hotkey Button

    @ViewBuilder
    private func hotkeyButton(hotkey: Character?, targetID: String) -> some View {
        let isCleared = clearedTarget == targetID

        Button {
            hotkeyTarget = targetID
        } label: {
            Text(hotkey != nil ? String(hotkey!).uppercased() : "SET KEY")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(hotkey != nil ? .primary : .tertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .frame(minWidth: 72)
                .background(Color(.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(
                            isCleared ? Color.orange : Color.secondary.opacity(0.25),
                            lineWidth: isCleared ? 1.5 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .help(isCleared ? "Key was already in use and has been reassigned" : "")
        .popover(isPresented: Binding(
            get: { hotkeyTarget == targetID },
            set: { if !$0 { hotkeyTarget = nil } }
        )) {
            HotkeyRecorder { key in
                applyHotkey(key, targetID: targetID)
                hotkeyTarget = nil
            }
        }
    }

    private func applyHotkey(_ key: Character?, targetID: String) {
        // Clear duplicate assignment if setting a new key
        if let key {
            clearDuplicateHotkey(key, excludingTarget: targetID)
        }

        let parts = targetID.split(separator: ":", maxSplits: 1)

        if parts.count == 2 && parts[0] == "app" {
            // App hotkey: "app:bundleID"
            let appID = String(parts[1])
            if let aIdx = appState.apps.firstIndex(where: { $0.id == appID }) {
                appState.apps[aIdx].hotkey = key
            }
            appDelegate.saveAppConfig()
            return
        }

        let browserID = String(parts[0])

        if parts.count == 2 {
            // Profile hotkey: "browserID:profileDir"
            let profileDir = String(parts[1])
            if let bIdx = appState.browsers.firstIndex(where: { $0.id == browserID }),
               let pIdx = appState.browsers[bIdx].profiles.firstIndex(where: { $0.directoryName == profileDir })
            {
                appState.browsers[bIdx].profiles[pIdx].hotkey = key
            }
        } else {
            // Browser hotkey
            if let bIdx = appState.browsers.firstIndex(where: { $0.id == browserID }) {
                appState.browsers[bIdx].hotkey = key
            }
        }
        appDelegate.saveBrowserConfig()
    }

    private func clearDuplicateHotkey(_ key: Character, excludingTarget: String) {
        // Check app hotkeys
        for aIdx in appState.apps.indices {
            let app = appState.apps[aIdx]
            let appTarget = "app:\(app.id)"
            if app.hotkey == key && appTarget != excludingTarget {
                withAnimation(.easeInOut(duration: 0.3)) {
                    appState.apps[aIdx].hotkey = nil
                    clearedTarget = appTarget
                }
                scheduleClearedDismiss()
                return
            }
        }

        for bIdx in appState.browsers.indices {
            let browser = appState.browsers[bIdx]

            // Check browser-level hotkey
            if browser.hotkey == key && browser.id != excludingTarget {
                withAnimation(.easeInOut(duration: 0.3)) {
                    appState.browsers[bIdx].hotkey = nil
                    clearedTarget = browser.id
                }
                scheduleClearedDismiss()
                return
            }

            // Check profile hotkeys
            for pIdx in browser.profiles.indices {
                let profile = browser.profiles[pIdx]
                let profileTarget = "\(browser.id):\(profile.directoryName)"
                if profile.hotkey == key && profileTarget != excludingTarget {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        appState.browsers[bIdx].profiles[pIdx].hotkey = nil
                        clearedTarget = profileTarget
                    }
                    scheduleClearedDismiss()
                    return
                }
            }
        }
    }

    private func scheduleClearedDismiss() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeOut(duration: 0.3)) {
                clearedTarget = nil
            }
        }
    }

    // MARK: - Profile Avatar

    private func profileAvatar(for profile: BrowserProfile) -> some View {
        let initial = profile.displayName.first.map { String($0).uppercased() } ?? "?"
        return Text(initial)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(Color.profileAvatar(for: profile.displayName), in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: 1.5))
    }
}
