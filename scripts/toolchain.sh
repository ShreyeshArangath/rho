#!/bin/bash
# Shared by build/test. Explicit SDK avoids stale xcrun SDK selection during CLT upgrades.
KEYMAPPER_DEVELOPER="$(xcode-select -p)"
KEYMAPPER_COMPILER="$(xcrun --find swiftc)"
if [[ -z "${KEYMAPPER_SDK:-}" ]]; then
    if [[ -d "$KEYMAPPER_DEVELOPER/SDKs/MacOSX.sdk" ]]; then
        KEYMAPPER_SDK="$KEYMAPPER_DEVELOPER/SDKs/MacOSX.sdk"
    else
        KEYMAPPER_SDK="$(xcrun --sdk macosx --show-sdk-path)"
    fi
fi
KEYMAPPER_TARGET="$(uname -m)-apple-macosx13.0"
mkdir -p .build/local
"$KEYMAPPER_COMPILER" -sdk "$KEYMAPPER_SDK" -target "$KEYMAPPER_TARGET" \
    -emit-library -static -emit-module -enable-testing -module-name KeymapperCore \
    Sources/KeymapperCore/*.swift -emit-module-path .build/local/KeymapperCore.swiftmodule \
    -o .build/local/libKeymapperCore.a
