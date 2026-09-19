# P8B

## New files

Core:
- Sources/Core/Diff/TextFileGuard.swift

State:
- Sources/State/Compare/FileDiffGuardState.swift

Views:
- Sources/Views/Compare/CompareWindowRegistry.swift

Tests:
- Tests/AboveDiffTests/TextFileGuardTests.swift

Docs:
- MELD_INTEGRATION_ARCHITECTURE.md
- MELD_INTEGRATION_USER_GUIDE.md
- P8_RELEASE_CHECKLIST.md

## Replace

- Sources/Views/Compare/FileDiffWindowPresenter.swift
- Sources/Views/Compare/ThreeWayDiffWindowPresenter.swift
- Sources/Views/Compare/ThreeWayMergeWindowPresenter.swift
- Sources/Views/Compare/ThreeWayMergeView.swift
- Sources/Views/Git/GitConflictMergeWindowPresenter.swift
- Sources/Views/Git/GitConflictMergeView.swift

## Adds

- duplicate-window reuse
- Dock/front activation behavior
- synchronized scrolling in merge source panes
- binary/oversize text-file guard primitives
- architecture documentation
- user guide
- release checklist

## Verify

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test

swift build -c release
```

Manual:
- open same file diff twice → existing window should come forward
- minimize compare window, invoke same compare → it should restore
- Three-Way Merge source panes sync-scroll
- Git conflict source panes sync-scroll
