#!/usr/bin/env bash
set -euo pipefail

FIXTURE_ROOT="${ABOVEDIFF_FIXTURE_ROOT:-/tmp/abovediff-git-fixture-multi}"

echo "== AboveDiff Multi-Conflict Test =="

rm -rf "$FIXTURE_ROOT"
mkdir -p "$FIXTURE_ROOT"
cd "$FIXTURE_ROOT"

git init -q
git config user.name "AboveDiff Fixture"
git config user.email "abovediff@example.test"

for name in one two three; do
  printf '%s = BASE\n' "$name" > "$name.txt"
done

git add .
git commit -q -m "base"

git switch -q -c local

for name in one two three; do
  printf '%s = LOCAL\n' "$name" > "$name.txt"
done

git commit -q -am "local"

git switch -q -c remote HEAD~1

for name in one two three; do
  printf '%s = REMOTE\n' "$name" > "$name.txt"
done

git commit -q -am "remote"

git switch -q local

set +e
git merge remote >/dev/null 2>&1
set -e

COUNT="$(git status --short | grep -c '^UU ')"

if [[ "$COUNT" -ne 3 ]]; then
  echo "error: expected 3 conflicts, got $COUNT"
  git status --short
  exit 1
fi

echo "Three conflicts prepared."
git status --short
echo
echo "AboveDiff should open one session at a time."
echo

git mergetool --tool=abovediff --no-prompt

echo
echo "Final status:"
git status --short

if git status --short | grep -q '^UU '; then
  echo "FAIL: unresolved conflicts remain."
  exit 1
fi

git diff --check

echo "PASS: all three conflicts completed."
