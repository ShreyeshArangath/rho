[rho](../README.md) · [Wiki](README.md) · Configuration

# Configuration reference

## File location

rho creates its configuration on first use at:

```text
~/Library/Application Support/PrivateKeymapper/config.json
```

`rho config` prints the path. The storage folder retains its original name so settings survive app updates.
Personal settings, recovery snapshots, and browser-profile app identifiers stay outside the repository.
New defaults do not replace an existing configuration.

For app letters, [`rho bind` and `rho unbind`](cli.md#edit-app-shortcuts) preserve the rest of the file.
To edit JSON, choose **ρ → Open Configuration**, save your changes, then choose **Reload Configuration**.
An invalid reload keeps the last working configuration active. `rho restart` also loads saved changes.

## JSON format

This example defines three bindings. Replacing your file with it replaces your saved binding list.

```json
{
	"version": 1,
	"superKey": "fn",
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

| Field | Meaning |
| --- | --- |
| `version` | Required. The supported version is `1`. |
| `superKey` | Optional. One of `fn`, `shift`, `control`, `option`, `command`, or `controlOption`. Defaults to `fn`. |
| `bindings` | Required array of input chords and actions. |
| `input.key` | Required physical key name. |
| `input.modifiers` | Required array of modifiers. Use `[]` for an unmodified key. |

In an input chord, `fn` means the selected super key. Existing bindings need no edits when you change that selection.
Input modifiers are `shift`, `control`, `option`, `command`, and `fn`. Their order does not matter.
A super-key choice that produces duplicate shortcuts or repeated modifiers is rejected without changing the saved settings.

## Actions

### Open an app

`openApp` requires `bundleIdentifier`. It does not accept an output key or modifiers.
rho launches through `NSWorkspace`, without shell commands from configuration.

Find an installed app's bundle identifier with:

```sh
plutil -extract CFBundleIdentifier raw '/Applications/zoom.us.app/Contents/Info.plist'
```

Zoom uses `us.zoom.xos`. Starter defaults use standard app identifiers.
Codex uses `com.openai.codex`, even when its app bundle is named ChatGPT. Linear's native app uses `com.linear`.
For an app installed through Chrome, use that app's own bundle identifier.

### Send a key

`sendKey` requires a valid output `key`. Its optional `modifiers` array defaults to no modifiers.
Output modifiers can be `shift`, `control`, `option`, and `command`. `fn` is not an output modifier.
An output action cannot repeat a modifier or include `bundleIdentifier`.

## Key names

Keys refer to physical US keyboard positions. Supported names are:

- Letters `a` through `z` and digits `0` through `9`.
- `space`, `backspace`, `escape`, `return`, and `tab`.
- `left`, `right`, `up`, `down`, `home`, `end`, `page_up`, `page_down`, and `forward_delete`.
- Function keys `f1` through `f18`.
- `equal`, `minus`, `left_bracket`, `right_bracket`, `quote`, `semicolon`, `backslash`, `comma`, `slash`, `period`, and `grave`.

Fn is an input modifier, not an ordinary input or output key. Escape is available as an ordinary key.
Caps Lock is not a configurable key. Media keys and released-key sequences are unsupported.

## Rejected configurations

rho rejects malformed JSON, unsupported versions, unknown keys or actions, duplicate chords, and repeated modifiers.
`openApp` and `sendKey` each require the fields listed above and reject incompatible action fields.
Duplicate chords are checked after the selected super key is expanded to its physical modifiers.

If a reload fails, fix the file and use **Reload Configuration** again.
The menu reports the error while the previous valid configuration remains active.
