#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if pgrep -x PrivateKeymapper >/dev/null; then
    echo 'Quit rho before replacing the app.' >&2
    exit 1
fi
./scripts/build.sh
mkdir -p "$HOME/Applications"
ditto "$PWD/dist/rho.app" "$HOME/Applications/rho.app"
mkdir -p "$HOME/.local/bin"
install -m 755 dist/rho "$HOME/.local/bin/rho"
open "$HOME/Applications/rho.app"
