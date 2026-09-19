# P4A Apply Notes

This is the first P4 implementation slice:
- ignore blank lines
- regex text filters
- sync points
- diff options UI
- normalized/original line mapping

## New files

```text
fxfile-macos/Sources/Core/Diff/DiffFilter.swift
fxfile-macos/Sources/Core/Diff/DiffSyncPoint.swift
fxfile-macos/Sources/Core/Diff/TextNormalizer.swift
fxfile-macos/Sources/Views/Compare/DiffOptionsSheet.swift
fxfile-macos/Tests/fxfileTests/TextNormalizerTests.swift
fxfile-macos/Tests/fxfileTests/DiffOptionsTests.swift
```

## Replace completely

```text
fxfile-macos/Sources/Core/Diff/DiffEngine.swift
fxfile-macos/Sources/State/Compare/EditableFileDiffState.swift
fxfile-macos/Sources/Views/Compare/FileDiffView.swift
```

## Verify

```bash
cd /Users/kimdongup/Bazel/fxfile/fxfile-macos
rm -rf .build
swift test
```

Then `swift run`, open File Diff, and verify Options:
- Ignore blank lines
- Regex filter
- Sync point

After P4A passes, P4B will add directory filename filters,
cancellation, cache, and large-file guards.
