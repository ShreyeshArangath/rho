#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/toolchain.sh
"$KEYMAPPER_COMPILER" -sdk "$KEYMAPPER_SDK" -target "$KEYMAPPER_TARGET" \
    -I .build/local -L .build/local -lKeymapperCore Tests/KeymapperCoreTests/*.swift \
    -o .build/local/CoreTests
.build/local/CoreTests
