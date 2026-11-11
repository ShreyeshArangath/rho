[rho](../README.md) · [Wiki](README.md) · Shortcuts

# Shortcut reference

## Default shortcuts

Hold **Fn/Globe** for at least **400 ms**, keep it held, then press the app letter.
Fn is the modifier often marked with a globe, not one of F1 through F12.

| Input | Action |
| --- | --- |
| Fn + C | Codex |
| Fn + B | Chrome |
| Fn + G | Ghostty |
| Fn + S | Slack |
| Fn + L | Linear |
| Fn + O | Obsidian |
| Fn + N | Notion |
| Fn + Z | Zoom |
| Either Shift + Space | Backspace, including held repeat |

An app shortcut opens or focuses the app once per press. Holding its letter does not launch it repeatedly.
Chrome uses its normal user-data directory, keeping the shortcut separate from Chrome instances used by other apps.
Caps Lock and Escape retain their normal behavior. rho does not install system key mappings.

## Super keys

The **ρ → Super Key** menu offers these choices:

| Super key | Activation |
| --- | --- |
| Fn/Globe, Shift, Control, Option, or Command | Hold for 400 ms, then press the letter |
| Control + Option | Press both modifiers and the letter, with no delay |

Either side of a selected modifier works. The checkmark identifies the current selection.
Changes apply immediately and persist across restarts. The app letters stay the same.
Fn/Globe is the default for new configurations.

Control + Option overlaps VoiceOver's default modifier. Choose another super key if you use VoiceOver.
Control alone or Option alone retains its normal behavior when the combination is selected.

## Timing and exact matches

Pressing a letter before the 400 ms threshold preserves its native shortcut and cancels launcher activation until you release the super key.
After the threshold, configured launcher letters belong to rho until you release that modifier.
Choose a modifier you can spare for the hold gesture.

Unassigned combinations pass through. Matches require the exact modifiers.
For example, Command + Shift + Space remains native with the default configuration.
Shift + Space keeps its Backspace behavior when you change the super key.

## Keyboard support

Key names refer to physical US keyboard positions. Your keyboard must expose its Fn modifier to macOS.
rho cannot intercept a firmware-only Fn key. Media keys and released-key sequences are not supported.

If the Globe action opens an input picker or emoji panel, set **System Settings → Keyboard → Press Fn/Globe key to → Do Nothing**.

Secure Input, the login screen, and apps that bypass Quartz events can prevent remapping.
See [troubleshooting](troubleshooting.md) for permission and interruption checks.

For custom app letters, use [`rho bind`](cli.md#edit-app-shortcuts).
For key remaps, use the [configuration file](configuration.md).
