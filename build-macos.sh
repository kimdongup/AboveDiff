#!/usr/bin/env bash
set -euo pipefail

# AboveDiff macOS Native Build and Packaging Script

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$PROJECT_ROOT/AboveDiff-macos"
DIST_DIR="$PROJECT_ROOT/dist"
APP_BUNDLE="$DIST_DIR/AboveDiff.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_BIN_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "=================================================="
echo " Building AboveDiff for macOS"
echo "=================================================="

# Ensure directories exist
mkdir -p "$DIST_DIR"

cd "$MACOS_DIR"

echo "==> Running Swift Unit Tests..."
swift test

echo "==> Compiling Release Binary via Swift Package Manager..."
swift build -c release

RELEASE_BIN="$MACOS_DIR/.build/release/AboveDiff"

if [ ! -f "$RELEASE_BIN" ]; then
    echo "Error: Release binary not found at $RELEASE_BIN"
    exit 1
fi

echo "==> Creating AboveDiff.app Bundle Structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_BIN_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$RELEASE_BIN" "$MACOS_BIN_DIR/AboveDiff"
chmod +x "$MACOS_BIN_DIR/AboveDiff"

ICON_PNG="$PROJECT_ROOT/assets/AboveDiffIcon.png"
ICON_ICNS="$PROJECT_ROOT/assets/AboveDiffIcon.icns"
APP_ICON="$MACOS_DIR/Resources/AppIcon.icns"

echo "==> Building AppIcon.icns from assets..."
mkdir -p "$MACOS_DIR/Resources"
if [ -f "$ICON_PNG" ]; then
    ICONSET="$(mktemp -d)/AppIcon.iconset"
    mkdir -p "$ICONSET"
    for spec in \
        "icon_16x16.png:16" \
        "icon_16x16@2x.png:32" \
        "icon_32x32.png:32" \
        "icon_32x32@2x.png:64" \
        "icon_128x128.png:128" \
        "icon_128x128@2x.png:256" \
        "icon_256x256.png:256" \
        "icon_256x256@2x.png:512" \
        "icon_512x512.png:512" \
        "icon_512x512@2x.png:1024"
    do
        name="${spec%%:*}"
        size="${spec##*:}"
        sips -z "$size" "$size" "$ICON_PNG" --out "$ICONSET/$name" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o "$APP_ICON"
    cp "$APP_ICON" "$ICON_ICNS"
    rm -rf "$(dirname "$ICONSET")"
elif [ -f "$ICON_ICNS" ]; then
    cp "$ICON_ICNS" "$APP_ICON"
fi

if [ -f "$APP_ICON" ]; then
    echo "==> Copying AppIcon.icns into the app bundle..."
    cp "$APP_ICON" "$RESOURCES_DIR/AppIcon.icns"
else
    echo "Error: App icon not found in assets/ or Resources/"
    exit 1
fi

# Create Info.plist
cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>AboveDiff</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.abovediff.macos</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>AboveDiff</string>
    <key>CFBundleDisplayName</key>
    <string>AboveDiff</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 AboveDiff project. All rights reserved.</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Ad-hoc code signing
echo "==> Performing ad-hoc code signing..."
codesign --force --deep --sign - "$APP_BUNDLE" || true

# Verify code sign
codesign --verify --deep --strict "$APP_BUNDLE" || true

echo "=================================================="
echo " Build Succeeded!"
echo " App Bundle created at: $APP_BUNDLE"
echo "=================================================="
