#!/bin/bash
set -euo pipefail

rho_main() (
rho_entry_source="$1"
shift
rho_mode='' rho_ref=main rho_explicit_ref=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --cli-only|--update)
            if [[ -n "$rho_mode" ]]; then echo 'Choose either --cli-only or --update.' >&2; exit 1; fi
            rho_mode="$1"; shift ;;
        --ref)
            if [[ $# -lt 2 || -z "$2" || "$2" == -* ]]; then echo '--ref requires a Git ref.' >&2; exit 1; fi
            rho_ref="$2"; rho_explicit_ref=true; shift 2 ;;
        --help|-h)
            cat <<'HELP'
Usage: install.sh [--cli-only | --update] [--ref REF]

Install rho.app and the rho command on macOS 13 or later.
Requires Apple Command Line Tools (xcode-select --install).
By default, an existing app is preserved and only the command is refreshed.

  --cli-only   Install only the command; do not start or replace the app
  --update     Rebuild and replace the app after you quit rho
  --ref REF    Download a specific Git branch, tag, or commit (default: main)
HELP
            exit 0 ;;
        *) printf 'Unknown option: %s. Run install.sh --help.\n' "$1" >&2; exit 1 ;;
    esac
done

if [[ "$(uname -s)" != Darwin ]]; then echo 'rho requires macOS 13 or later.' >&2; exit 1; fi
rho_macos_version="$(sw_vers -productVersion)"
if [[ "${rho_macos_version%%.*}" -lt 13 ]]; then echo 'rho requires macOS 13 or later.' >&2; exit 1; fi
if ! xcode-select -p >/dev/null 2>&1 || ! xcrun --find swiftc >/dev/null 2>&1; then
    echo 'Install Apple Command Line Tools first: xcode-select --install' >&2
    echo 'Finish that installation, then run this installer again.' >&2
    exit 1
fi

rho_source='' rho_download=''
if [[ "$rho_explicit_ref" == false && -n "$rho_entry_source" ]]; then
    rho_candidate="$(cd "$(dirname "$rho_entry_source")" && pwd)"
    if [[ -f "$rho_candidate/Package.swift" && -f "$rho_candidate/scripts/install.sh" ]]; then
        rho_source="$rho_candidate"
    fi
fi
if [[ -z "$rho_source" ]]; then
    rho_download="$(mktemp -d "${TMPDIR:-/tmp}/rho-install.XXXXXX")"
    trap 'rm -rf -- "$rho_download"' EXIT
    printf 'Downloading rho source (%s)…\n' "$rho_ref"
    curl --fail --location --silent --show-error \
        "https://github.com/ShreyeshArangath/rho/archive/$rho_ref.tar.gz" -o "$rho_download/source.tar.gz"
    mkdir "$rho_download/source"
    tar -xzf "$rho_download/source.tar.gz" -C "$rho_download/source" --strip-components 1
    rho_source="$rho_download/source"
fi

if [[ -n "$rho_mode" ]]; then
    "$rho_source/scripts/install.sh" "$rho_mode"
else
    "$rho_source/scripts/install.sh"
fi
)

rho_main "${BASH_SOURCE[0]:-}" "$@"
