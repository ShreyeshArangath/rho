[rho](../README.md) · Wiki

# rho wiki

rho runs a local macOS menu-bar app for keyboard shortcuts. The `rho` command starts and manages the installed app.

| Guide | Use it to |
| --- | --- |
| [Installation](installation.md) | Install rho, add the CLI, or update the app |
| [Shortcuts](shortcuts.md) | Look up app letters and choose a super key |
| [Configuration](configuration.md) | Edit the JSON file or define a key remap |
| [CLI](cli.md) | Look up terminal commands and exit codes |
| [Troubleshooting](troubleshooting.md) | Restore remapping or recover a legacy Caps Lock mapping |
| [Uninstall](uninstall.md) | Remove rho and choose whether to keep settings |
| [Development](development.md) | Build from source and verify changes |

Start with [installation](installation.md), then run `rho status` and try a [shortcut](shortcuts.md).

The app needs macOS Accessibility approval. The terminal command does not request separate Accessibility access.
Settings stay in `~/Library/Application Support/PrivateKeymapper/config.json` across app updates.
