#!/bin/bash
# Builds build/FillLight.app (and a zip for GitHub Releases) with Command Line Tools only.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-1.0.0}"
APP="build/FillLight.app"

swift build -c release --product FillLight
BIN="$(swift build -c release --show-bin-path)/FillLight"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/FillLight"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>FillLight</string>
    <key>CFBundleDisplayName</key><string>FillLight</string>
    <key>CFBundleIdentifier</key><string>io.github.seanlu2006.FillLight</string>
    <key>CFBundleExecutable</key><string>FillLight</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key><string>io.github.seanlu2006.FillLight</string>
            <key>CFBundleURLSchemes</key><array><string>filllight</string></array>
        </dict>
    </array>
</dict>
</plist>
PLIST

# Ad-hoc signature: enough to run locally. Downloaded copies still need
# right-click → Open the first time, since the app is not notarized.
codesign --force --sign - "$APP"

(cd build && ditto -c -k --keepParent FillLight.app "FillLight-macOS-${VERSION}.zip")
echo "Built $APP and build/FillLight-macOS-${VERSION}.zip"
