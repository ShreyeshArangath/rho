#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/build-cli.sh
mkdir -p "$HOME/.local/bin"
install -m 755 dist/rho "$HOME/.local/bin/rho"
printf 'Installed: %s/.local/bin/rho\n' "$HOME"
