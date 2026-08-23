#!/usr/bin/env bash
set -euo pipefail

# fxfile macOS Native Build and Packaging Script

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$PROJECT_ROOT/fxfile-macos"
DIST_DIR="$PROJECT_ROOT/dist"
APP_BUNDLE="$DIST_DIR/fxfile.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_BIN_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "=================================================="
echo " Building fxfile for macOS"
echo "=================================================="

# Ensure directories exist
mkdir -p "$DIST_DIR"

cd "$MACOS_DIR"

echo "==> Running Swift Unit Tests..."
swift test

echo "==> Compiling Release Binary via Swift Package Manager..."
swift build -c release

RELEASE_BIN="$MACOS_DIR/.build/release/fxfile"

if [ ! -f "$RELEASE_BIN" ]; then
    echo "Error: Release binary not found at $RELEASE_BIN"
    exit 1
fi

echo "==> Creating fxfile.app Bundle Structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_BIN_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$RELEASE_BIN" "$MACOS_BIN_DIR/fxfile"
chmod +x "$MACOS_BIN_DIR/fxfile"

# Copy Resources if available
if [ -f "$MACOS_DIR/Resources/AppIcon.icns" ]; then
    echo "==> Copying AppIcon.icns..."
    cp "$MACOS_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
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
    <string>fxfile</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.fxfile.macos</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>fxfile</string>
    <key>CFBundleDisplayName</key>
    <string>fxfile</string>
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
    <string>Copyright © 2026 fxfile project. All rights reserved.</string>
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
