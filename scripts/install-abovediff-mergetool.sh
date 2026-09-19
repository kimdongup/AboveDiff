#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${ABOVEDIFF_APP_PATH:-/Applications/AboveDiff.app}"
BUNDLED_CLI="$APP_PATH/Contents/Helpers/abovediff"
CLI_TARGET="/usr/local/bin/abovediff"

echo "== AboveDiff Git Mergetool Installer =="

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: AboveDiff.app not found:"
  echo "  $APP_PATH"
  echo
  echo "Install AboveDiff.app into /Applications first."
  exit 1
fi

if [[ ! -x "$BUNDLED_CLI" ]]; then
  echo "error: bundled abovediff CLI not found:"
  echo "  $BUNDLED_CLI"
  echo
  echo "This AboveDiff.app was not packaged with the Git CLI helper."
  exit 1
fi

echo "[1/4] Installing CLI launcher"

if [[ -w "$(dirname "$CLI_TARGET")" ]]; then
  ln -sf "$BUNDLED_CLI" "$CLI_TARGET"
else
  sudo mkdir -p "$(dirname "$CLI_TARGET")"
  sudo ln -sf "$BUNDLED_CLI" "$CLI_TARGET"
fi

echo "[2/4] Configuring Git"

git config --global merge.tool abovediff

git config --global mergetool.abovediff.cmd \
'abovediff --mergetool --base "$BASE" --local "$LOCAL" --remote "$REMOTE" --merged "$MERGED"'

git config --global mergetool.abovediff.trustExitCode true

echo "[3/4] Verifying CLI"

command -v abovediff
abovediff --version

echo "[4/4] Verifying Git configuration"

git config --global --get merge.tool
git config --global --get mergetool.abovediff.cmd
git config --global --get mergetool.abovediff.trustExitCode

echo
echo "AboveDiff Git mergetool integration installed."
