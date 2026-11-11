[rho](../README.md) · [Wiki](README.md) · Development

# Build and verify rho

Use macOS 13 or later with Apple Command Line Tools and a macOS SDK.
Scripts compile Swift directly. Swift Package Manager and XCTest are not required.

## Run the tests

From the repository root, run:

```sh
./scripts/test.sh
```

The dependency-free runner checks the shortcut engine, configuration validation, Chrome profile lock parsing, CLI argument parsing and shortcut edits, and legacy recovery policy.
It also runs installer scenarios in temporary homes, including first install, repeat install, CLI-only install, and updates.
Bootstrap checks cover arguments, unsupported systems, and missing developer tools.
The tests do not change your live app or keyboard settings.
Engine tests cover hold timing, native short chords, repeat suppression, release ordering, all default app actions including Zoom, and preservation of unrelated shortcuts.

## Build without installing

Build the app and terminal command:

```sh
./scripts/build.sh
```

The outputs are `dist/rho.app` and `dist/rho`. To build only the CLI, run:

```sh
./scripts/build-cli.sh
```

To select an SDK explicitly, run:

```sh
KEYMAPPER_SDK=/path/to/MacOSX.sdk ./scripts/build.sh
```

Builds target the current Mac's architecture with a minimum deployment version of macOS 13.
`Package.swift` supports editors and SwiftPM. If SwiftPM is available, `swift run CoreTests` runs the core tests.

## Install a build

Use `./install.sh` for a first installation. A repeated default install keeps an existing app and refreshes only the CLI.
Use `./install.sh --cli-only` to keep the app untouched, or `./install.sh --update` after quitting rho to replace it.
See the [installation guide](installation.md) for the complete behavior.

The app has an ad-hoc signature and is not notarized. A Developer ID signature can replace ad-hoc signing if you have one.
Replacing the app after a rebuild may require refreshing its Accessibility entry.

## Verify the installed behavior

After granting Accessibility approval:

1. Run `rho status` to confirm that the installed app has an enabled keyboard event tap.
2. In a disposable document, tap Escape and test an app letter after holding Fn for 400 ms. Release Fn before a letter to confirm it does not launch.
3. Press Fn and a letter before 400 ms. Confirm native behavior, then hold a launcher letter to check that it opens only once.
4. Test both Shift keys with Space, held repeat, releasing Shift first, plain Space, and Command + Shift + Space.
5. Check Caps Lock, pause and resume, sleep and wake, keyboard reconnection, and permission revocation. No synthetic key should remain held.
6. Save and reload a custom shortcut. Try an invalid key or duplicate chord and confirm that a failed reload keeps the previous configuration active.
7. Try a missing app and check the menu's error message. Confirm Chrome focuses its normal profile and Zoom uses the configured Z shortcut.
8. With Control + Option selected, test immediate app launching and passthrough for either modifier alone or an extra modifier.

Physical keyboard checks matter. Targeted automation events can bypass the session event tap and do not prove shortcut interception.

## Runtime boundaries

`KeymapperCore` owns the engine, configuration data, CLI commands, storage, and Chrome profile lookup.
`PrivateKeymapper` owns the menu-bar app, event tap, macOS launch behavior, and legacy HID recovery.
`RhoCLI` manages the installed app and reads or updates the shared configuration file.

The app has no network code, telemetry, keystroke logging, or third-party dependencies.
Only the state needed for holds and matching key events stays in memory.
Startup diagnostics report app status and login registration, never typed content.
