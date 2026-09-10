#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release
BIN="$(swift build -c release --show-bin-path)"
APP="$PWD/.build/Specter.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/terminfo"
cp "$BIN/Specter" "$BIN/SpecterPTY" "$APP/Contents/MacOS/"
cp -R "$BIN/Specter_MetalTerminal.bundle" "$APP/Contents/Resources/"
tic -x -o "$APP/Contents/Resources/terminfo" Resources/specter.terminfo
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>app.specter.terminal</string>
<key>CFBundleName</key><string>Specter</string>
<key>CFBundleExecutable</key><string>Specter</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSHumanReadableCopyright</key><string>Copyright © 2026 Specter contributors. MIT License.</string>
</dict></plist>
PLIST
xattr -cr "$APP"
codesign --force --sign - "$APP/Contents/MacOS/SpecterPTY"
codesign --force --sign - "$APP"
printf 'Built %s\n' "$APP"
