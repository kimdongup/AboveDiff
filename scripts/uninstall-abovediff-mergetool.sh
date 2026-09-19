#!/usr/bin/env bash
set -euo pipefail

CLI_TARGET="/usr/local/bin/abovediff"

echo "Removing AboveDiff Git mergetool configuration..."

git config --global --unset-all mergetool.abovediff.cmd 2>/dev/null || true
git config --global --unset-all mergetool.abovediff.trustExitCode 2>/dev/null || true

if [[ "$(git config --global --get merge.tool 2>/dev/null || true)" == "abovediff" ]]; then
  git config --global --unset-all merge.tool || true
fi

if [[ -L "$CLI_TARGET" ]]; then
  if [[ -w "$(dirname "$CLI_TARGET")" ]]; then
    rm -f "$CLI_TARGET"
  else
    sudo rm -f "$CLI_TARGET"
  fi
fi

echo "Done."
