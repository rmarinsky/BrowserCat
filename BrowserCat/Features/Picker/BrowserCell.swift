import SwiftUI

struct BrowserCell: View {
    let browser: InstalledBrowser
    let profile: BrowserProfile?
    let isFocused: Bool
    var compact: Bool = false

    init(browser: InstalledBrowser, isFocused: Bool, profile: BrowserProfile? = nil, compact: Bool = false) {
        self.browser = browser
        self.profile = profile
        self.isFocused = isFocused
        self.compact = compact
    }

    private var displayHotkey: Character? {
        profile?.hotkey ?? browser.hotkey
    }

    var body: some View {
        if compact {
            compactBody
        } else {
            normalBody
        }
    }

    private var compactBody: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottomLeading) {
                if let icon = browser.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 24))
                        .frame(width: 32, height: 32)
                }

                // Profile avatar badge
                if let profile {
                    profileBadge(for: profile)
                        .offset(x: -3, y: 3)
                }
            }

            // Hotkey badge
            if let hotkey = displayHotkey {
                Text(String(hotkey).uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 14, height: 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 3))
                    .offset(x: 3, y: -3)
            }
        }
        .frame(width: 44, height: 44)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isFocused ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
    }

    private var normalBody: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottomLeading) {
                    if let icon = browser.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: "globe")
                            .font(.system(size: 32))
                            .frame(width: 40, height: 40)
                    }

                    // Profile avatar badge
                    if let profile {
                        profileBadge(for: profile)
                            .offset(x: -4, y: 4)
                    }
                }

                // Hotkey badge
                if let hotkey = displayHotkey {
                    Text(String(hotkey).uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 4))
                        .offset(x: 4, y: -4)
                }
            }

            HStack(spacing: 2) {
                Text(profile?.displayName ?? browser.displayName)
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .truncationMode(.tail)

                if profile == nil && browser.hasProfiles {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

        }
        .frame(width: 72, height: 78)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isFocused ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
    }

    private func profileBadge(for profile: BrowserProfile) -> some View {
        let initial = profile.displayName.first.map { String($0).uppercased() } ?? "?"
        return Text(initial)
            .font(.system(size: 7, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 16, height: 16)
            .background(avatarColor(for: profile.displayName), in: Circle())
            .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
    }

    private func avatarColor(for name: String) -> Color {
        .profileAvatar(for: name)
    }
}

// MARK: - Shared profile avatar color

extension Color {
    static func profileAvatar(for name: String) -> Color {
        let colors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal, .indigo]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
}
