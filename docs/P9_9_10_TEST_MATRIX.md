# P9.9-P9.10 Test Matrix

## Prerequisites

```bash
command -v abovediff
abovediff --version

git config --global --get merge.tool
git config --global --get mergetool.abovediff.cmd
git config --global --get mergetool.abovediff.trustExitCode
```

Expected:

```text
/usr/local/bin/abovediff
abovediff 1.0.0
abovediff
... --mergetool ...
true
```

## Test A — Successful single conflict

```bash
cd /Users/kimdongup/Bazel/AboveDiff
chmod +x scripts/test-abovediff-mergetool-fixture.sh
./scripts/test-abovediff-mergetool-fixture.sh
```

Expected:
- AboveDiff opens automatically
- one merge session
- Save & Resolve
- CLI exit 0
- `git diff --check` passes

## Test B — Cancel

```bash
chmod +x scripts/test-abovediff-mergetool-cancel.sh
./scripts/test-abovediff-mergetool-cancel.sh
```

Expected:
- click Cancel
- CLI returns non-zero
- `UU test.txt` remains

## Test C — Multiple conflicts

```bash
chmod +x scripts/test-abovediff-mergetool-multi.sh
./scripts/test-abovediff-mergetool-multi.sh
```

Expected:
- 3 AboveDiff sessions handled sequentially
- no `UU` entries remain
- `git diff --check` passes

## Test D — Paths with spaces / Unicode

Use:

```bash
export ABOVEDIFF_FIXTURE_ROOT="/tmp/AboveDiff 한글 Test"
./scripts/test-abovediff-mergetool-fixture.sh
```

Expected:
- session opens normally
- quoted paths are preserved
- successful exit 0

## Test E — AboveDiff already running

Start:

```bash
open -a /Applications/AboveDiff.app
```

Then run fixture test.

Expected:
- existing app receives request
- no extra unintended app process is needed
- merge window opens

## Test F — AboveDiff not running

```bash
killall AboveDiff 2>/dev/null || true
./scripts/test-abovediff-mergetool-fixture.sh
```

Expected:
- app launches automatically
- merge window opens
- terminal waits for session completion
