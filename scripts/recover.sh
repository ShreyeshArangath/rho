#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
INSTALLED="$HOME/Applications/rho.app/Contents/MacOS/PrivateKeymapper"
if [[ -x "$INSTALLED" ]]; then
    exec "$INSTALLED" --recover
fi
exec "$PWD/dist/rho.app/Contents/MacOS/PrivateKeymapper" --recover
