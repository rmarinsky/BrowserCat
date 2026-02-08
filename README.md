# BrowserCat

A macOS menu bar app that lets you choose which browser (or app) opens every link. Set BrowserCat as your default browser and a sleek picker appears near your cursor whenever you click a URL anywhere on the system.

## Features

- **Browser picker** - floating panel appears near the cursor with all installed browsers
- **Native app routing** - open links directly in Slack, Teams, Discord, Figma, Zoom, Telegram, and more
- **URL rules** - auto-route links by host, substring, or regex to a specific browser or app
- **Browser profiles** - pick a Chrome/Edge/Brave/Firefox profile before opening
- **Private mode** - hold Option or Shift + hotkey to open in incognito/private
- **Keyboard hotkeys** - assign a single key to each browser, profile, or app for instant opening
- **Launch at login** - optional, via the Settings window
- **Lightweight** - lives in the menu bar, no dock icon

## Supported Browsers

Safari, Chrome, Firefox, Arc, Edge, Brave, Opera, Vivaldi, Chromium, Orion (Kagi), Zen, Waterfox, SigmaOS, Tor Browser, Whale, Yandex, and more. Any browser installed on your Mac is auto-detected.

## Supported Apps

Teams, Slack, Discord, Figma, Notion, Spotify, Zoom, Linear, Telegram, WhatsApp, 1Password, VS Code, Obsidian, Jira, Miro, Loom. Apps that match the link's host are promoted to the top of the picker.

## Installation

### Homebrew (recommended)

```bash
brew install --cask rmarinsky/tap/browsercat
```

### Manual

1. Download the latest `.dmg` from [GitHub Releases](https://github.com/rmarinsky/BrowserCat/releases/latest)
2. Open the `.dmg` and drag **BrowserCat** to Applications
3. Launch BrowserCat and set it as the default browser in Settings

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Assigned hotkey | Open link in that browser/app |
| Option/Shift + hotkey | Open in private/incognito mode |
| Arrow keys | Navigate the picker grid |
| Return | Open in the focused browser |
| Escape | Dismiss the picker |

Hotkeys are configured per-browser and per-profile in **Settings > Apps**.

## Build from Source

Requires Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
git clone https://github.com/rmarinsky/BrowserCat.git
cd BrowserCat
xcodegen generate
open BrowserCat.xcodeproj
```

Build and run the **BrowserCat** scheme (Release) or **BrowserCat DEV** scheme (Debug).

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel

## License

[MIT](LICENSE)
