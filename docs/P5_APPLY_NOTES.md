# P5 Apply Notes

Adds native 3-way compare:

```text
LOCAL | BASE | REMOTE
```

Classification:
- equal
- localOnly
- remoteOnly
- sameChange
- conflict

## New files

```text
AboveDiff-macos/Sources/Core/Diff3/ThreeWayDiffChunk.swift
AboveDiff-macos/Sources/Core/Diff3/ThreeWayDiffResult.swift
AboveDiff-macos/Sources/Core/Diff3/ThreeWayDiffOptions.swift
AboveDiff-macos/Sources/Core/Diff3/ThreeWayDiffEngine.swift

AboveDiff-macos/Sources/State/Compare/ThreeWayDiffState.swift

AboveDiff-macos/Sources/Views/Compare/ThreeWayTextPane.swift
AboveDiff-macos/Sources/Views/Compare/ThreeWayOverviewMap.swift
AboveDiff-macos/Sources/Views/Compare/ThreeWayDiffView.swift
AboveDiff-macos/Sources/Views/Compare/ThreeWayDiffWindowPresenter.swift

AboveDiff-macos/Tests/AboveDiffTests/ThreeWayDiffEngineTests.swift
```

No existing source file needs to be replaced for the initial P5 implementation.

## Verify

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

## Temporary manual launch

Until menu wiring is added, call:

```swift
ThreeWayDiffWindowPresenter.open(
    localURL: localURL,
    baseURL: baseURL,
    remoteURL: remoteURL
)
```

P6 will build the actual merge resolver on this engine.
