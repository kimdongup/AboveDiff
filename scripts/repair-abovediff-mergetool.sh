#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INSTALLER="$ROOT_DIR/scripts/install-abovediff-mergetool.sh"

echo "== Repair AboveDiff Git Mergetool =="

if [[ ! -x "$INSTALLER" ]]; then
  chmod +x "$INSTALLER"
fi

"$INSTALLER"

echo
echo "Repair complete."
