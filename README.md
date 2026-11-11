<p align="center">
  <img src="docs/assets/rho-keycap.png" width="840" alt="A single teal keyboard keycap with a cream Greek rho symbol.">
</p>

# rho

Your apps, one shortcut away.

rho is a local macOS keyboard remapper with a menu-bar app and a terminal command.
Hold your super key, press a letter, and open or focus an app.

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

Already have the app? Install only the terminal command:

```sh
curl -fsSL https://raw.githubusercontent.com/ShreyeshArangath/rho/main/install.sh | bash -s -- --cli-only
```

Repeating the default install refreshes the CLI and preserves your existing app's Accessibility approval.
Use [`--update`](docs/installation.md#update-the-app) when you want to rebuild and replace the app.
Your saved shortcuts survive installation and updates.

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

`bind` assigns an app to a letter using your selected super key and preserves your other shortcuts.
Changed bindings restart the running app to apply the settings.
The CLI manages the installed app without replacing it or requesting its own Accessibility access.

For an existing configuration, run `rho bind z us.zoom.xos` to add Zoom.
New defaults do not overwrite saved settings.

[All CLI commands](docs/cli.md) · [Configuration file](docs/configuration.md)

## Local keyboard processing

The app processes keyboard events on your Mac. It has no network code, telemetry, or keystroke logging.
It uses macOS Accessibility APIs without a keyboard driver or third-party runtime dependencies.
Secure Input and the login screen can prevent remapping.

The source build is ad-hoc signed and is not notarized.
Rebuilding the app may require [refreshing its Accessibility approval](docs/troubleshooting.md#accessibility-is-enabled-but-rho-is-inactive).

## Wiki

The [checked-in wiki](docs/README.md) covers setup, daily use, and development.

| Guide | What it covers |
| --- | --- |
| [Installation](docs/installation.md) | First install, CLI-only install, updates, and PATH |
| [Shortcuts](docs/shortcuts.md) | Defaults, super keys, timing, and keyboard support |
| [Configuration](docs/configuration.md) | JSON format, custom remaps, and validation |
| [CLI](docs/cli.md) | Commands, arguments, and exit codes |
| [Troubleshooting](docs/troubleshooting.md) | Permissions, inactive shortcuts, and legacy recovery |
| [Uninstall](docs/uninstall.md) | Remove the app, command, and optional saved settings |
| [Development](docs/development.md) | Build, tests, signing, and manual verification |
