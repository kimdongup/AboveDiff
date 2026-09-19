# P9 Final Apply Notes

## Add

Core:
- AboveDiff-macos/Sources/Core/Git/MergeTool/MergeToolSessionMaintenance.swift
- AboveDiff-macos/Sources/Core/Git/MergeTool/GitMergetoolInstallStatus.swift

State:
- AboveDiff-macos/Sources/State/Git/GitIntegrationState.swift

View:
- AboveDiff-macos/Sources/Views/Git/GitIntegrationStatusView.swift

Tests:
- AboveDiff-macos/Tests/AboveDiffTests/MergeToolSessionMaintenanceTests.swift

Scripts:
- scripts/check-abovediff-mergetool.sh
- scripts/repair-abovediff-mergetool.sh

Docs:
- docs/P9_FINALIZATION.md
- docs/P9_RELEASE_CHECKLIST.md

## Replace

- AboveDiff-macos/CLI/Sources/abovediff/main.swift

## Optional Preferences wiring

Embed:

```swift
GitIntegrationStatusView()
```

inside the existing Preferences Git/Advanced section.

This view is intentionally status-only.
Install/repair remains an explicit shell script in P9 to avoid silently changing
global Git configuration from the GUI.

## Verify

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
swift build -c release

cd CLI
rm -rf .build
swift build -c release
```

Then:

```bash
cd /Users/kimdongup/Bazel/AboveDiff

chmod +x \
  scripts/check-abovediff-mergetool.sh \
  scripts/repair-abovediff-mergetool.sh

./scripts/check-abovediff-mergetool.sh
```
