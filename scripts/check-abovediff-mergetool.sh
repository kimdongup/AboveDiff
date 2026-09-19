#!/usr/bin/env bash
set -euo pipefail

FAIL=0

echo "== AboveDiff Git Mergetool Status =="

if [[ -d "/Applications/AboveDiff.app" ]]; then
  echo "OK   AboveDiff.app: /Applications/AboveDiff.app"
else
  echo "FAIL AboveDiff.app not found in /Applications"
  FAIL=1
fi

CLI="$(command -v abovediff 2>/dev/null || true)"

if [[ -n "$CLI" ]]; then
  echo "OK   CLI: $CLI"
else
  echo "FAIL abovediff not found in PATH"
  FAIL=1
fi

TOOL="$(git config --global --get merge.tool 2>/dev/null || true)"

if [[ "$TOOL" == "abovediff" ]]; then
  echo "OK   merge.tool = abovediff"
else
  echo "FAIL merge.tool = ${TOOL:-<unset>}"
  FAIL=1
fi

CMD="$(git config --global --get mergetool.abovediff.cmd 2>/dev/null || true)"

if [[ "$CMD" == *"abovediff --mergetool"* ]]; then
  echo "OK   mergetool.abovediff.cmd"
else
  echo "FAIL mergetool.abovediff.cmd"
  FAIL=1
fi

TRUST="$(git config --global --get mergetool.abovediff.trustExitCode 2>/dev/null || true)"

if [[ "$TRUST" == "true" ]]; then
  echo "OK   trustExitCode = true"
else
  echo "FAIL trustExitCode = ${TRUST:-<unset>}"
  FAIL=1
fi

if [[ "$FAIL" -eq 0 ]]; then
  echo
  echo "PASS: AboveDiff Git mergetool is fully configured."
else
  echo
  echo "Run:"
  echo "  ./scripts/repair-abovediff-mergetool.sh"
fi

exit "$FAIL"
