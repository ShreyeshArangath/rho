# rho

rho is a local macOS menu-bar app for keyboard shortcuts and app launching. It processes keyboard events on your Mac, with no network code, telemetry, keystroke logging, third-party dependencies, or keyboard driver. Requires macOS 13 or later and Accessibility permission.

## Install

With Apple's Command Line Tools installed, run:

```sh
./scripts/test.sh
./scripts/install.sh
```

The installer builds and signs the app locally, installs `~/Applications/rho.app`, and opens it. Click the Greek **ρ** icon in the menu bar for controls. There is no Dock icon or main window.

Choose **Grant Accessibility Permission…** and enable **rho** in **System Settings → Privacy & Security → Accessibility**. Reopen the app if macOS requests it, then choose **Resume**. Keyboard remapping stays inactive until permission is available.

rho registers **Launch at Login** when it starts. Approve the login item in System Settings if macOS requests it. You can disable it from the menu; manually opening rho registers it again if it is unregistered.

To build without installing or opening the app:

```sh
./scripts/build.sh
```

The output is `dist/rho.app`. Scripts use `swiftc` directly; Swift Package Manager and XCTest are not required. To select a different SDK, run `KEYMAPPER_SDK=/path/to/MacOSX.sdk ./scripts/build.sh`. `Package.swift` supports editors and SwiftPM; `swift run CoreTests` runs the tests when SwiftPM is available.

Rebuilding changes the app's ad-hoc signature. macOS may require removing and re-adding its Accessibility entry afterward. A Developer ID signature can replace ad-hoc signing if you have one. This build is for local use and is not notarized.

## Shortcuts

Hold the **Fn/Globe** key for at least **400 ms**, keep it held, then press the app letter. Escape retains its ordinary behavior. Fn presses and unassigned Fn chords retain their native macOS behavior.

| Input | Action |
| --- | --- |
| Either Shift + Space | Backspace, including held-key repeat |
| Long-press Fn + C | Codex |
| Long-press Fn + B | Chrome |
| Long-press Fn + G | Ghostty |
| Long-press Fn + S | Slack |
| Long-press Fn + L | Linear |
| Long-press Fn + O | Obsidian |
| Long-press Fn + N | Notion |

App actions open or focus the app once per press. Caps Lock retains its normal behavior; rho does not install system key mappings. A letter pressed before 400 ms keeps its native Fn behavior and cancels launcher activation until Fn is released. Fn is the modifier key, often marked with a globe, rather than one of F1 through F12.

Only exact modifier combinations match. For example, Command + Shift + Space retains its normal behavior with the default configuration.

## Configure shortcuts

Choose **Open Configuration**, edit and save the file, then choose **Reload Configuration**. Invalid changes leave the previous working configuration active.

The file is created on first run at:

```text
~/Library/Application Support/PrivateKeymapper/config.json
```

The storage folder keeps its original name so existing settings survive app updates. It is outside the repository. Personal settings, recovery snapshots, and browser-profile app identifiers are not included in the source.

Example configuration:

```json
{
  "version": 1,
  "bindings": [
    {
      "input": { "key": "space", "modifiers": ["shift"] },
      "action": { "type": "sendKey", "key": "backspace" }
    },
    {
      "input": { "key": "c", "modifiers": ["fn"] },
      "action": { "type": "openApp", "bundleIdentifier": "com.openai.codex" }
    },
    {
      "input": { "key": "h", "modifiers": ["fn"] },
      "action": { "type": "sendKey", "key": "left", "modifiers": ["command", "shift"] }
    }
  ]
}
```

Input modifiers are `shift`, `control`, `option`, `command`, and `fn`. The input `modifiers` array is required; modifier order does not matter.

`sendKey` requires an output `key`. Output `modifiers` defaults to none and permits standard modifiers only, excluding `fn`. Do not include a bundle identifier.

`openApp` requires a `bundleIdentifier`. Do not include output keys or modifiers. Launching uses `NSWorkspace`, without shell commands from configuration. For Chrome-installed apps, use their own bundle identifier in your local configuration.

Find an app's bundle identifier with:

```sh
plutil -extract CFBundleIdentifier raw '/Applications/Notion.app/Contents/Info.plist'
```

Starter defaults use standard app bundle identifiers. Codex uses `com.openai.codex`; the desktop app may be named ChatGPT. Linear's native app uses `com.linear`.

Key names refer to physical US keyboard positions. Supported names are `a` through `z`, `0` through `9`, `space`, `backspace`, `escape`, `return`, `tab`, `left`, `right`, `up`, `down`, `home`, `end`, `page_up`, `page_down`, `forward_delete`, `f1` through `f18`, `equal`, `minus`, `left_bracket`, `right_bracket`, `quote`, `semicolon`, `backslash`, `comma`, `slash`, `period`, and `grave`.

Fn is an input modifier, not an ordinary input or output key. Escape can be configured as an ordinary key. Duplicate chords, repeated modifiers, invalid keys and actions, malformed JSON, and unsupported versions are rejected. Media keys and released-key sequences are not supported. A keyboard must expose its Fn modifier to macOS; firmware-only Fn keys cannot be intercepted. If your single-press Globe action opens an input picker or emoji panel that interferes with launching, choose **Do Nothing** under **System Settings → Keyboard → Press Fn/Globe key to**.

## Pause, recovery, and removal

**Pause** and **Quit** release synthetic keys and stop interception. No system mappings are installed.

If you previously used the Caps Lock version, startup restores its saved Caps mapping before enabling the new engine. Recovery can also be run after quitting:

```sh
./scripts/recover.sh
```

Without the source folder:

```sh
"$HOME/Applications/rho.app/Contents/MacOS/PrivateKeymapper" --recover
```

Recovery only undoes the old Caps-to-F18 mapping when it is still present. It preserves unrelated mappings and subsequent Caps changes. It uses `caps-recovery.json` in the app's settings folder and refuses to run while another instance is running. Do not delete that file before recovery succeeds.

To remove rho, disable **Launch at Login**, choose **Quit**, and remove its Accessibility entry. Delete `~/Applications/rho.app`. After any legacy recovery succeeds, you can also remove the settings folder. No privileged helper or launch daemon is installed.

## Verify behavior

`./scripts/test.sh` checks the shortcut engine and legacy recovery without changing your keyboard. Tests cover normal Escape, the 400 ms Fn threshold, native short Fn chords, release ordering, repeat suppression, all seven launch actions, Backspace repeat, reset/release behavior, configuration validation, and preservation of unrelated legacy mappings.

After granting Accessibility permission:

1. In a disposable text document, tap Escape and try each app letter after holding Fn for 400 ms. Release Fn before pressing a letter to confirm it does not launch.
2. Press Fn and a letter before 400 ms. Check that the native Fn behavior remains available. Hold a launcher letter to confirm the app opens only once.
3. Test both Shift keys with Space, held repeat, releasing Shift before Space, plain Space, and Command + Shift + Space.
4. Check normal Caps Lock behavior, pause and resume, sleep and wake, keyboard reconnection, and permission revocation. No synthetic keys should remain held.
5. Save and reload a custom shortcut. Try an invalid key or duplicate chord, then check that the previous configuration still works. Try a missing app and check the menu's error message.

Secure Input, the login screen, and apps that bypass Quartz events cannot be guaranteed to receive remaps. Secure Input and permissions are checked every two seconds. Event-tap interruption pauses remapping and requires **Resume**. Permission loss, sleep, and Secure Input suspend it automatically.

No keyboard-event history is stored. Only state needed for holds and matching key-down/key-up events stays in memory. Startup diagnostics report app status and login registration, never typed content.
