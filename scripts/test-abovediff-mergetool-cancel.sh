#!/usr/bin/env bash
set -euo pipefail

FIXTURE_ROOT="${ABOVEDIFF_FIXTURE_ROOT:-/tmp/abovediff-git-fixture-cancel}"

echo "== AboveDiff Git Mergetool Cancel Test =="

rm -rf "$FIXTURE_ROOT"
mkdir -p "$FIXTURE_ROOT"
cd "$FIXTURE_ROOT"

git init -q
git config user.name "AboveDiff Fixture"
git config user.email "abovediff@example.test"

printf 'value = BASE\n' > test.txt
git add test.txt
git commit -q -m "base"

git switch -q -c local
printf 'value = LOCAL\n' > test.txt
git commit -q -am "local"

git switch -q -c remote HEAD~1
printf 'value = REMOTE\n' > test.txt
git commit -q -am "remote"

git switch -q local

set +e
git merge remote >/dev/null 2>&1
set -e

echo "Conflict prepared."
echo
echo "When AboveDiff opens, click Cancel or close the merge window."
echo

set +e
git mergetool --tool=abovediff --no-prompt test.txt
STATUS=$?
set -e

echo
echo "Exit code: $STATUS"

if [[ "$STATUS" -eq 0 ]]; then
  echo "FAIL: Cancel should return non-zero."
  exit 1
fi

if ! git status --short | grep -q '^UU test.txt$'; then
  echo "FAIL: conflict is no longer marked unresolved."
  git status --short
  exit 1
fi

echo "PASS: cancel returned non-zero and conflict remained unresolved."
