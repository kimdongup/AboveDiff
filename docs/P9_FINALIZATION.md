# P9 Finalization

AboveDiff external Git mergetool integration is complete when all items below pass.

## Runtime architecture

```text
git mergetool
  ↓
/usr/local/bin/abovediff
  ↓
request.json
  ↓
/Applications/AboveDiff.app
  ↓
MergeToolSessionCoordinator
  ↓
ExternalMergeToolView
  ↓
Save & Resolve / Cancel
  ↓
result.json
  ↓
CLI exit status
  ↓
Git continues or stops
```

## Product / CLI naming

```text
Product      AboveDiff
CLI          abovediff
Git tool     abovediff
```

## Production paths

```text
/Applications/AboveDiff.app
/usr/local/bin/abovediff
~/Library/Caches/AboveDiff/MergeSessions
```

## Health check

```bash
cd /Users/kimdongup/Bazel/AboveDiff

chmod +x \
  scripts/check-abovediff-mergetool.sh \
  scripts/repair-abovediff-mergetool.sh

./scripts/check-abovediff-mergetool.sh
```

## Repair

```bash
./scripts/repair-abovediff-mergetool.sh
```

## Timeout

Default external merge session timeout:

```text
1800 seconds (30 minutes)
```

Override for debugging:

```bash
ABOVEDIFF_SESSION_TIMEOUT=60 git mergetool
```

## Stale sessions

CLI removes sessions older than 24 hours before creating a new session.

## Regression

Run:

```bash
./scripts/test-abovediff-mergetool-fixture.sh
./scripts/test-abovediff-mergetool-cancel.sh
./scripts/test-abovediff-mergetool-multi.sh
```

## Release verification

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
swift test
swift build -c release

cd CLI
swift build -c release
```

Then:

```bash
command -v abovediff
abovediff --version
git mergetool --tool=abovediff
```
