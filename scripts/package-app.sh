#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
swift build -c release
BIN="$ROOT/.build/release/RedDim"
APP="$ROOT/RedDim.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cat > "$APP/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>RedDim</string>
  <key>CFBundleIdentifier</key><string>space.johann.RedDim</string>
  <key>CFBundleName</key><string>RedDim</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.3</string>
  <key>CFBundleVersion</key><string>3</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>RedDim uses your location only to time sunset and sunrise for the auto ramp.</string>
</dict>
</plist>
PLIST
cp "$BIN" "$APP/Contents/MacOS/RedDim"
chmod +x "$APP/Contents/MacOS/RedDim"
echo "Built $APP"
