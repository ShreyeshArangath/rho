#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/toolchain.sh
"$KEYMAPPER_COMPILER" -sdk "$KEYMAPPER_SDK" -target "$KEYMAPPER_TARGET" -O \
    -I .build/local -L .build/local -lKeymapperCore Sources/PrivateKeymapper/*.swift \
    -o .build/local/PrivateKeymapper
BIN_DIR="$PWD/.build/local"
APP="$PWD/dist/rho.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
"$KEYMAPPER_COMPILER" -sdk "$KEYMAPPER_SDK" -target "$KEYMAPPER_TARGET" \
    scripts/generate-icon.swift -o .build/local/generate-icon
.build/local/generate-icon "$PWD/.build/icons"
iconutil -c icns .build/icons/rho.iconset -o "$APP/Contents/Resources/rho.icns"
cp .build/icons/RhoMenu.png "$APP/Contents/Resources/RhoMenu.png"
cp .build/icons/rho.png dist/rho.png
cp "$BIN_DIR/PrivateKeymapper" "$APP/Contents/MacOS/PrivateKeymapper"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.privatekeymapper.app</string>
<key>CFBundleName</key><string>rho</string>
<key>CFBundleDisplayName</key><string>rho</string>
<key>CFBundleExecutable</key><string>PrivateKeymapper</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundleVersion</key><string>2</string>
<key>CFBundleIconFile</key><string>rho.icns</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>NSAccessibilityUsageDescription</key><string>Remap your configured keyboard shortcuts locally.</string>
</dict></plist>
PLIST
plutil -lint "$APP/Contents/Info.plist"
codesign --force --sign - --identifier local.privatekeymapper.app "$APP"
printf 'Built: %s\n' "$APP"
./scripts/build-cli.sh
