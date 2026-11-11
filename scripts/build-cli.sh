#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/toolchain.sh
mkdir -p dist
"$KEYMAPPER_COMPILER" -sdk "$KEYMAPPER_SDK" -target "$KEYMAPPER_TARGET" -O \
    -I .build/local -L .build/local -lKeymapperCore Sources/RhoCLI/*.swift -o dist/rho
printf 'Built: %s/dist/rho\n' "$PWD"
