#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-0.2.0}"
APP_DIR="$ROOT_DIR/dist/GifBar.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"
swift scripts/generate-icon.swift
iconutil -c icns assets/GifBar.iconset -o assets/GifBar.icns
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$ROOT_DIR/.build/release/GifBar" "$MACOS_DIR/GifBar"
if [[ -f "$ROOT_DIR/assets/GifBar.icns" ]]; then
  cp "$ROOT_DIR/assets/GifBar.icns" "$RESOURCES_DIR/GifBar.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>GifBar</string>
  <key>CFBundleIdentifier</key>
  <string>dev.afif.gifbar</string>
  <key>CFBundleName</key>
  <string>GifBar</string>
  <key>CFBundleDisplayName</key>
  <string>GifBar</string>
  <key>CFBundleIconFile</key>
  <string>GifBar</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>__VERSION__</string>
  <key>CFBundleVersion</key>
  <string>__VERSION__</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

/usr/bin/sed -i '' "s/__VERSION__/$VERSION/g" "$CONTENTS_DIR/Info.plist"
/usr/bin/codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
