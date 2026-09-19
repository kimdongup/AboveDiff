#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DMG_PATH="$ROOT_DIR/dist/AboveDiff.dmg"

PROFILE="${ABOVEDIFF_NOTARY_PROFILE:-AboveDiffNotary}"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "error: DMG not found:"
  echo "  $DMG_PATH"
  exit 1
fi

echo "Submitting AboveDiff.dmg for notarization..."

xcrun notarytool submit \
  "$DMG_PATH" \
  --keychain-profile "$PROFILE" \
  --wait

echo "Stapling notarization ticket..."

xcrun stapler staple "$DMG_PATH"

echo "Validating stapled ticket..."

xcrun stapler validate "$DMG_PATH"

echo
echo "Notarization complete:"
echo "  $DMG_PATH"
