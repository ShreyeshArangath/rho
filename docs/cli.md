[rho](../README.md) · [Wiki](README.md) · CLI

# CLI reference

The `rho` command manages `~/Applications/rho.app` and its saved shortcuts.
It does not request separate Accessibility access. Quit development copies before starting the installed app.

## Commands

| Command | Result |
| --- | --- |
| `rho` or `rho start` | Start the app in the background, or report that it is already running. |
| `rho stop` | Ask the installed app to quit and wait for it to exit. |
| `rho restart` | Stop the app, then start it with the saved settings. |
| `rho status` | Report whether the installed app has an enabled keyboard event tap. |
| `rho shortcuts` | List configured chords with their selected super key expanded. |
| `rho bind <key> <bundle-id>` | Assign an installed app to a super-key launcher. |
| `rho unbind <key>` | Remove that key's app launcher. |
| `rho config` | Print the configuration file path. |
| `rho help`, `rho --help`, or `rho -h` | Print help. |

`start` requires the app at `~/Applications/rho.app`. It refuses to start a second copy while another Rho bundle is running.
`stop` does not force-kill a process. A restart clears the menu's Pause state.

## Edit app shortcuts

```sh
rho bind z us.zoom.xos
rho shortcuts
rho unbind z
```

`bind` uses your current super key. For example, with Control + Option selected, binding `z` produces Control + Option + Z.
The key is case-insensitive. The bundle identifier must identify an installed app.

`bind` replaces the matching super-key chord and preserves unrelated shortcuts.
`unbind` removes only its app launcher, preserving key remaps such as Shift + Space.
If settings change while the installed app is running, the CLI restarts it to load them.
An unchanged binding does not restart the app. If the app is stopped, the settings apply at its next start.

For an existing settings file, run `rho bind z us.zoom.xos` to add Zoom.
Installing a version with new defaults does not overwrite saved settings.

For manual JSON edits, run `rho restart` or use **ρ → Reload Configuration** after saving.
See the [configuration reference](configuration.md) for key remaps and supported fields.

## Status and exit codes

`rho status` returns exit code `0` when the installed app has an enabled keyboard event tap.
A stopped app or inactive remapping returns `1`.
Process presence alone does not mean remapping is active.

Other commands return `0` on success and `1` for invalid arguments or an operation failure.
Errors print to standard error. `rho status`, `rho shortcuts`, and help print to standard output.

If remapping is inactive, check **Pause**, Accessibility approval, and Secure Input.
See [troubleshooting](troubleshooting.md) for the recovery steps.
