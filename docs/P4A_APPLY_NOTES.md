# P4A Apply Notes

This is the first P4 implementation slice:
- ignore blank lines
- regex text filters
- sync points
- diff options UI
- normalized/original line mapping

## New files

```text
AboveDiff-macos/Sources/Core/Diff/DiffFilter.swift
AboveDiff-macos/Sources/Core/Diff/DiffSyncPoint.swift
AboveDiff-macos/Sources/Core/Diff/TextNormalizer.swift
AboveDiff-macos/Sources/Views/Compare/DiffOptionsSheet.swift
AboveDiff-macos/Tests/AboveDiffTests/TextNormalizerTests.swift
AboveDiff-macos/Tests/AboveDiffTests/DiffOptionsTests.swift
```

## Replace completely

```text
AboveDiff-macos/Sources/Core/Diff/DiffEngine.swift
AboveDiff-macos/Sources/State/Compare/EditableFileDiffState.swift
AboveDiff-macos/Sources/Views/Compare/FileDiffView.swift
```

## Verify

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

Then `swift run`, open File Diff, and verify Options:
- Ignore blank lines
- Regex filter
- Sync point

After P4A passes, P4B will add directory filename filters,
cancellation, cache, and large-file guards.
