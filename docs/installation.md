[rho](../README.md) · [Wiki](README.md) · Installation

# Install rho

## Requirements

Use macOS 13 or later with Apple Command Line Tools installed.
The installer compiles for your Mac's architecture and needs a macOS SDK.

To install Apple's tools, run:

```sh
xcode-select --install
```

Complete Apple's installer before installing rho. The source build does not require Homebrew, npm, Swift Package Manager, or XCTest.

## First install

```sh
curl -fsSL https://raw.githubusercontent.com/ShreyeshArangath/rho/main/install.sh | bash
```

The installer downloads the source, builds the app and CLI, and installs them for your user:

| Component | Location |
| --- | --- |
| Menu-bar app | `~/Applications/rho.app` |
| Terminal command | `~/.local/bin/rho` |
| Saved configuration | `~/Library/Application Support/PrivateKeymapper/config.json` |

The first installation opens rho. Click **ρ → Grant Accessibility Permission…**, then enable **rho** in **System Settings → Privacy & Security → Accessibility**.
Reopen the app if macOS asks, then choose **Resume** from the **ρ** menu.

rho registers **Launch at Login** when it starts. Approve the login item if macOS requests it.
You can disable it from the menu. Manually opening rho registers it again if it is unregistered.

Open a new terminal, then check the app:

```sh
rho status
```

An active app prints `rho: active` with its process ID. See [troubleshooting](troubleshooting.md) if remapping is inactive.

## Install from a checkout

From the repository root, run:

```sh
./install.sh
```

`./scripts/install.sh` remains available for checkout use with the same default, `--cli-only`, and `--update` modes.

## Keep an existing app

Repeating the default install refreshes the CLI and keeps the installed `rho.app` unchanged.
This preserves the app's code signature and its existing Accessibility approval.
Installation does not overwrite your saved configuration.

For an existing configuration, add Zoom explicitly:

```sh
rho bind z us.zoom.xos
```

## Install only the CLI

```sh
curl -fsSL https://raw.githubusercontent.com/ShreyeshArangath/rho/main/install.sh | bash -s -- --cli-only
```

From a checkout, use `./install.sh --cli-only` or `./scripts/install-cli.sh`.
This mode never starts, stops, replaces, or signs the app again. An app installation is required for `rho start`.

## Update the app

Quit rho before replacing it:

```sh
rho stop
curl -fsSL https://raw.githubusercontent.com/ShreyeshArangath/rho/main/install.sh | bash -s -- --update
```

From a checkout, run `./install.sh --update` after quitting the app.
The update rebuilds and replaces the app, refreshes the CLI, and keeps saved settings.
An updated ad-hoc signature may require an [Accessibility refresh](troubleshooting.md#accessibility-is-enabled-but-rho-is-inactive).
The build is not notarized.

## PATH and source selection

If `~/.local/bin` is absent from PATH, the installer adds it to your shell's startup file.
For zsh, it uses `$ZDOTDIR/.zshrc` when `ZDOTDIR` is exported, or `~/.zshrc` otherwise.
For Bash, it uses the first existing file among `~/.bash_profile`, `~/.bash_login`, and `~/.profile`. If none exists, it creates `~/.bash_profile`.
It preserves the file's existing contents and does not shadow an existing Bash login profile. Open a new terminal to use the new entry.
In your current terminal, use the absolute command printed by the installer, such as `~/.local/bin/rho status`.
For other shells, add `~/.local/bin` to PATH using that shell's configuration.

The downloaded installer accepts `--ref REF` to choose a source branch, tag, or commit:

```sh
curl -fsSL https://raw.githubusercontent.com/ShreyeshArangath/rho/main/install.sh | bash -s -- --ref main --cli-only
```

Run `./install.sh --help` for the supported flags. See [development](development.md) for builds without installation.
