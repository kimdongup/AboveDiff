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
AboveDiff-macos/Sources/Core/Diff/DiffPerformance.swift
AboveDiff-macos/Sources/Core/Directory/DirectoryNameFilter.swift
AboveDiff-macos/Sources/Views/Compare/SyncPointSummaryBar.swift
AboveDiff-macos/Tests/AboveDiffTests/DirectoryNameFilterTests.swift
AboveDiff-macos/Tests/AboveDiffTests/DiffPerformanceTests.swift
```

## Replace completely

```text
AboveDiff-macos/Sources/Core/Diff/DiffEngine.swift
AboveDiff-macos/Sources/Core/Directory/DirectoryCompareOptions.swift
AboveDiff-macos/Sources/Core/Directory/DirectoryCompareEngine.swift
AboveDiff-macos/Sources/State/Compare/FolderCompareState.swift
AboveDiff-macos/Sources/Views/Compare/DiffOptionsSheet.swift
AboveDiff-macos/Sources/Views/Compare/FileDiffView.swift
AboveDiff-macos/Sources/Views/Compare/FolderCompareView.swift
```

## Verify

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

Then:
- Sync Point UI should display line 1 for internal index 0
- active sync points appear above the diff as `L n ↔ R m`
- Folder Compare include/exclude filters work
- Cancel stops a long comparison
- large documents show a performance warning and suppress per-line highlighting
