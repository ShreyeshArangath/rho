[rho](../README.md) · [Wiki](README.md) · Troubleshooting

# Restore keyboard shortcuts

Run `rho status` first. An enabled keyboard event tap reports `rho: active` with the process ID.
A running app can still have remapping paused or suspended.

## Accessibility is enabled but rho is inactive

A rebuild changes rho's ad-hoc signature. System Settings can display an old approval while the updated app remains untrusted.

1. Quit rho with `rho stop` or **ρ → Quit rho**.
2. Open **System Settings → Privacy & Security → Accessibility**.
3. Remove only rho's existing entry.
4. Add `~/Applications/rho.app` and enable it. Authenticate if macOS asks.
5. Run `rho start`, then `rho status`.

Use the installed app at that exact path. Rebuilding again changes its signature again.
The CLI does not need its own Accessibility entry.

## Shortcuts are paused or interrupted

Choose **ρ → Resume** if rho is paused or keyboard interception was interrupted.
An event-tap interruption pauses remapping until you resume it.
Permission loss, sleep, and Secure Input suspend remapping automatically.
rho checks permissions and Secure Input every two seconds.

If Secure Input is active, leave the secure-input field or app and check status again.
Remapping cannot be guaranteed at the login screen or in apps that bypass Quartz events.

## An app letter does nothing

1. Run `rho shortcuts` to confirm the saved letter and super key.
2. For a single-modifier super key, hold it for at least 400 ms before pressing the letter.
3. Release extra modifiers. Only exact combinations match.
4. Check that the target app is installed. The menu reports **App unavailable** when its bundle identifier cannot be resolved.

For Zoom in an existing configuration, run `rho bind z us.zoom.xos`.
For a firmware-only Fn key, choose another super key. See [keyboard support](shortcuts.md#keyboard-support).

If the Globe action opens an input picker or emoji panel, set **System Settings → Keyboard → Press Fn/Globe key to → Do Nothing**.

## The CLI cannot start the app

Install the app at `~/Applications/rho.app` with the [installer](installation.md).
If another development copy is running, quit it before `rho start`.
The instance lock prevents recovery or a second copy from racing the running app.

If `rho` is not found, open a new terminal or run `~/.local/bin/rho help`.
Check the [PATH instructions](installation.md#path-and-source-selection) for your shell.

## A configuration reload failed

Fix the reported error in the [configuration file](configuration.md), save it, then choose **Reload Configuration**.
An invalid reload keeps the previous valid settings active.
Installing new defaults does not overwrite an existing settings file.

## Recover a legacy Caps Lock mapping

Current rho leaves Caps Lock unchanged. Older versions mapped Caps Lock to F18 and saved recovery information.
Startup restores that legacy mapping before enabling the current shortcut engine.

If recovery needs to run separately, quit rho first. From a checkout, run:

```sh
./scripts/recover.sh
```

Without the source checkout, run:

```sh
"$HOME/Applications/rho.app/Contents/MacOS/PrivateKeymapper" --recover
```

Recovery changes only the old mapping when it is still present. It preserves unrelated mappings and later Caps Lock changes.
The recovery file is `~/Library/Application Support/PrivateKeymapper/caps-recovery.json`.
Do not delete it before recovery succeeds. Recovery refuses to run while another rho instance holds the application lock.
