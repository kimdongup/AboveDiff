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
fxfile-macos/Sources/Core/Diff3/ThreeWayDiffChunk.swift
fxfile-macos/Sources/Core/Diff3/ThreeWayDiffResult.swift
fxfile-macos/Sources/Core/Diff3/ThreeWayDiffOptions.swift
fxfile-macos/Sources/Core/Diff3/ThreeWayDiffEngine.swift

fxfile-macos/Sources/State/Compare/ThreeWayDiffState.swift

fxfile-macos/Sources/Views/Compare/ThreeWayTextPane.swift
fxfile-macos/Sources/Views/Compare/ThreeWayOverviewMap.swift
fxfile-macos/Sources/Views/Compare/ThreeWayDiffView.swift
fxfile-macos/Sources/Views/Compare/ThreeWayDiffWindowPresenter.swift

fxfile-macos/Tests/fxfileTests/ThreeWayDiffEngineTests.swift
```

No existing source file needs to be replaced for the initial P5 implementation.

## Verify

```bash
cd /Users/kimdongup/Bazel/fxfile/fxfile-macos
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
