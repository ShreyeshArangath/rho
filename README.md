<p align="center">
  <img src="docs/assets/rho-keycap.png" width="840" alt="A single teal keyboard keycap with a cream Greek rho symbol.">
</p>

# rho

rho launches apps and remaps keys on macOS. It runs in the menu bar and comes with a `rho` terminal command.

[Install](#install) · [Shortcuts](#shortcuts) · [CLI](#terminal-command) · [Wiki](docs/README.md)

## Install

Requires macOS 13 or later and [Apple Command Line Tools](docs/installation.md#requirements).
The installer builds rho from source on your Mac.

```sh
curl -fsSL https://raw.githubusercontent.com/ShreyeshArangath/rho/main/install.sh | bash
```

From a checkout, run `./install.sh`.
The app goes in `~/Applications/rho.app`, and the command goes in `~/.local/bin/rho`.

1. Choose **ρ → Grant Accessibility Permission…** from the menu bar.
2. Enable **rho** in **System Settings → Privacy & Security → Accessibility**. Reopen the app if macOS requests it.
3. Open a new terminal so your shell picks up the command's PATH entry.
4. Run `rho status` to check that keyboard remapping is active.

Click **ρ** in the menu bar for **Super Key**, **Pause**, and configuration controls.
rho has no Dock icon or main window. It registers to launch at login.

Install only the terminal command:

```sh
curl -fsSL https://raw.githubusercontent.com/ShreyeshArangath/rho/main/install.sh | bash -s -- --cli-only
```

Re-running the default installer updates the CLI and keeps the app's existing Accessibility approval.
Use [`--update`](docs/installation.md#update-the-app) to rebuild and replace the app.
Installation and updates keep your saved shortcuts.

The source build is ad-hoc signed and is not notarized.
Rebuilding the app may require [refreshing its Accessibility approval](docs/troubleshooting.md#accessibility-is-enabled-but-rho-is-inactive).

## Shortcuts

By default, hold **Fn/Globe** for **400 ms**, keep it held, then press a letter.

| Shortcut | Action |
| --- | --- |
| Fn + C | Codex |
| Fn + B | Chrome |
| Fn + G | Ghostty |
| Fn + S | Slack |
| Fn + L | Linear |
| Fn + O | Obsidian |
| Fn + N | Notion |
| Fn + Z | Zoom |
| Shift + Space | Backspace, including held repeat |

Choose **Super Key → Control + Option** in the **ρ** menu for instant app shortcuts.
For example, **Control + Option + Z** opens Zoom with no hold delay.
This combination overlaps VoiceOver's default modifier. Choose another super key if you use VoiceOver.

Fn/Globe, Shift, Control, Option, and Command are also available with the 400 ms hold.
Escape and Caps Lock keep their normal behavior.

[Shortcut behavior and keyboard support](docs/shortcuts.md)

## Terminal command

Run `rho` to start the app in the background.

```sh
rho status
rho shortcuts
rho bind z us.zoom.xos
rho restart
rho stop
rho help
```

`rho bind` assigns an app to your selected super key and a letter. Other shortcuts stay as they are.
The CLI restarts rho after a binding changes. Only the menu-bar app needs Accessibility permission.

For an existing configuration, run `rho bind z us.zoom.xos` to add Zoom.
New defaults do not overwrite saved settings.

[All CLI commands](docs/cli.md) · [Configuration file](docs/configuration.md)

## Privacy

The app processes keyboard events on your Mac. It has no network code, telemetry, or keystroke logging.
It uses macOS Accessibility APIs without a keyboard driver or third-party runtime dependencies.
Secure Input and the login screen can prevent remapping.

## Wiki

[Wiki index](docs/README.md)

| Guide | What it covers |
| --- | --- |
| [Installation](docs/installation.md) | First install, CLI-only install, updates, and PATH |
| [Shortcuts](docs/shortcuts.md) | Defaults, super keys, timing, and keyboard support |
| [Configuration](docs/configuration.md) | JSON format, custom remaps, and validation |
| [CLI](docs/cli.md) | Commands, arguments, and exit codes |
| [Troubleshooting](docs/troubleshooting.md) | Permissions, inactive shortcuts, and legacy recovery |
| [Uninstall](docs/uninstall.md) | Remove the app, command, and optional saved settings |
| [Development](docs/development.md) | Build, tests, signing, and manual verification |
