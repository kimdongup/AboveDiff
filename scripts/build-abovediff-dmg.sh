#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="AboveDiff"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
DMG_DIR="$ROOT_DIR/dist/dmg"
DMG_PATH="$ROOT_DIR/dist/$APP_NAME.dmg"

CLI_DIR="$ROOT_DIR/AboveDiff-macos/CLI"
HELPERS_DIR="$APP_BUNDLE/Contents/Helpers"
BUNDLED_CLI="$HELPERS_DIR/abovediff"

CODESIGN_IDENTITY="${ABOVEDIFF_CODESIGN_IDENTITY:--}"
SKIP_NOTARIZE="${ABOVEDIFF_SKIP_NOTARIZE:-1}"

echo "== AboveDiff release + DMG builder =="

cd "$ROOT_DIR"

echo "[1/8] Building AboveDiff.app"

if [[ ! -x "$ROOT_DIR/build-macos.sh" ]]; then
  echo "error: build-macos.sh not found or not executable:"
  echo "  $ROOT_DIR/build-macos.sh"
  exit 1
fi

"$ROOT_DIR/build-macos.sh"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "error: expected app bundle was not created:"
  echo "  $APP_BUNDLE"
  exit 1
fi

echo "[2/8] Building abovediff CLI (release)"

cd "$CLI_DIR"

swift build -c release

CLI_BIN_DIR="$(swift build -c release --show-bin-path)"
CLI_SOURCE="$CLI_BIN_DIR/abovediff"

if [[ ! -x "$CLI_SOURCE" ]]; then
  echo "error: abovediff CLI not found:"
  echo "  $CLI_SOURCE"
  exit 1
fi

echo "[3/8] Embedding CLI into app bundle"

mkdir -p "$HELPERS_DIR"
cp -f "$CLI_SOURCE" "$BUNDLED_CLI"
chmod 755 "$BUNDLED_CLI"

echo "Embedded:"
echo "  $BUNDLED_CLI"

echo "[4/8] Signing app bundle"

# Sign nested executable first.
codesign \
  --force \
  --options runtime \
  --timestamp \
  --sign "$CODESIGN_IDENTITY" \
  "$BUNDLED_CLI"

# Re-sign the whole application after embedding the CLI.
codesign \
  --force \
  --deep \
  --options runtime \
  --timestamp \
  --sign "$CODESIGN_IDENTITY" \
  "$APP_BUNDLE"

echo "[5/8] Verifying signatures"

codesign \
  --verify \
  --deep \
  --strict \
  --verbose=2 \
  "$APP_BUNDLE"

spctl \
  --assess \
  --type execute \
  --verbose \
  "$APP_BUNDLE" \
  || true

echo "[6/8] Preparing DMG staging directory"

rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

ditto "$APP_BUNDLE" "$DMG_DIR/$APP_NAME.app"

ln -s /Applications "$DMG_DIR/Applications"

cat > "$DMG_DIR/README.txt" <<'EOF'
AboveDiff

Installation:
1. Drag AboveDiff.app to Applications.
2. Open AboveDiff once.
3. To install Git mergetool integration, run the installer included with the release package or use the Git Integration instructions.

AboveDiff product name: AboveDiff
Git CLI / mergetool name: abovediff
EOF

echo "[7/8] Creating DMG"

rm -f "$DMG_PATH"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "[8/8] Final verification"

hdiutil verify "$DMG_PATH"

echo
echo "App:"
echo "  $APP_BUNDLE"
echo
echo "DMG:"
echo "  $DMG_PATH"
echo

if [[ "$SKIP_NOTARIZE" == "1" ]]; then
  echo "Notarization skipped."
  echo "Set ABOVEDIFF_SKIP_NOTARIZE=0 after configuring notarytool credentials."
fi

echo
echo "Done."
