#!/usr/bin/env bash
set -euo pipefail

FIXTURE_ROOT="${ABOVEDIFF_FIXTURE_ROOT:-/tmp/abovediff-git-fixture}"

echo "== AboveDiff Git Mergetool Fixture Test =="

if ! command -v abovediff >/dev/null 2>&1; then
  echo "error: abovediff is not in PATH."
  echo "Run scripts/install-abovediff-mergetool.sh first."
  exit 1
fi

if [[ "$(git config --global --get merge.tool 2>/dev/null || true)" != "abovediff" ]]; then
  echo "error: global merge.tool is not 'abovediff'."
  exit 1
fi

rm -rf "$FIXTURE_ROOT"
mkdir -p "$FIXTURE_ROOT"
cd "$FIXTURE_ROOT"

git init -q
git config user.name "AboveDiff Fixture"
git config user.email "abovediff@example.test"

cat > test.txt <<'EOF'
line1
value = BASE
line3
EOF

git add test.txt
git commit -q -m "base"

BASE_BRANCH="$(git branch --show-current)"

git switch -q -c local
cat > test.txt <<'EOF'
line1
value = LOCAL
line3
EOF

git commit -q -am "local change"

git switch -q -c remote HEAD~1
cat > test.txt <<'EOF'
line1
value = REMOTE
line3
EOF

git commit -q -am "remote change"

git switch -q local

set +e
git merge remote >/tmp/abovediff-fixture-merge.log 2>&1
MERGE_STATUS=$?
set -e

if [[ "$MERGE_STATUS" -eq 0 ]]; then
  echo "error: fixture did not produce a conflict."
  cat /tmp/abovediff-fixture-merge.log
  exit 1
fi

STATUS="$(git status --short)"

if ! grep -q '^UU test.txt$' <<<"$STATUS"; then
  echo "error: expected 'UU test.txt'"
  echo "$STATUS"
  exit 1
fi

echo
echo "Fixture created successfully:"
echo "  $FIXTURE_ROOT"
echo
echo "Conflict state:"
git status --short

echo
echo "Launching AboveDiff..."
echo "Resolve the conflict and click 'Save & Resolve'."
echo

set +e
git mergetool --tool=abovediff --no-prompt test.txt
MERGETOOL_STATUS=$?
set -e

echo
echo "git mergetool exit code: $MERGETOOL_STATUS"

if [[ "$MERGETOOL_STATUS" -ne 0 ]]; then
  echo "FAIL: AboveDiff returned a non-zero exit code."
  echo "Conflict remains:"
  git status --short
  exit "$MERGETOOL_STATUS"
fi

echo
echo "Merged file:"
cat test.txt

echo
echo "Git status:"
git status --short

echo
echo "Running git diff --check..."
git diff --check

echo
echo "PASS: AboveDiff mergetool completed successfully."
echo
echo "To remove the fixture:"
echo "  rm -rf '$FIXTURE_ROOT'"
