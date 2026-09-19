# P6 Apply Notes

Adds native 3-way merge resolution.

## New Core files

```text
Sources/Core/Merge/
├── MergeDecision.swift
├── MergeResult.swift
└── ThreeWayMergeEngine.swift
```

## New State file

```text
Sources/State/Compare/
└── ThreeWayMergeState.swift
```

## New Views

```text
Sources/Views/Compare/
├── MergeDecisionGutter.swift
├── MergeResultPane.swift
├── ConflictNavigator.swift
├── ThreeWayMergeView.swift
└── ThreeWayMergeWindowPresenter.swift
```

## New tests

```text
Tests/AboveDiffTests/
└── ThreeWayMergeEngineTests.swift
```

No existing file replacement is required.

## Verify

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

## Manual launch

```swift
ThreeWayMergeWindowPresenter.open(
    localURL: localURL,
    baseURL: baseURL,
    remoteURL: remoteURL
)
```

Expected:
- non-conflicting changes auto-merge
- conflicts start unresolved
- Use Local / Remote / Base
- Local→Remote / Remote→Local
- editable merged result
- save result
- unresolved-conflict warning before save
