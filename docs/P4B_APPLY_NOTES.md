# P4B Apply Notes

Adds:
- 1-based Sync Point UI
- visible Sync Point summary markers
- Folder Compare include/exclude filename filters
- glob or regex name filtering
- comparison cancellation
- diff result cache
- large-file guard

## New files

```text
fxfile-macos/Sources/Core/Diff/DiffPerformance.swift
fxfile-macos/Sources/Core/Directory/DirectoryNameFilter.swift
fxfile-macos/Sources/Views/Compare/SyncPointSummaryBar.swift
fxfile-macos/Tests/fxfileTests/DirectoryNameFilterTests.swift
fxfile-macos/Tests/fxfileTests/DiffPerformanceTests.swift
```

## Replace completely

```text
fxfile-macos/Sources/Core/Diff/DiffEngine.swift
fxfile-macos/Sources/Core/Directory/DirectoryCompareOptions.swift
fxfile-macos/Sources/Core/Directory/DirectoryCompareEngine.swift
fxfile-macos/Sources/State/Compare/FolderCompareState.swift
fxfile-macos/Sources/Views/Compare/DiffOptionsSheet.swift
fxfile-macos/Sources/Views/Compare/FileDiffView.swift
fxfile-macos/Sources/Views/Compare/FolderCompareView.swift
```

## Verify

```bash
cd /Users/kimdongup/Bazel/fxfile/fxfile-macos
rm -rf .build
swift test
```

Then:
- Sync Point UI should display line 1 for internal index 0
- active sync points appear above the diff as `L n ↔ R m`
- Folder Compare include/exclude filters work
- Cancel stops a long comparison
- large documents show a performance warning and suppress per-line highlighting
