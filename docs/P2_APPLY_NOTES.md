# P2 Apply Notes

## New files

```text
AboveDiff-macos/Sources/State/Compare/FileDiffState.swift
AboveDiff-macos/Sources/Views/Compare/DiffTextPane.swift
AboveDiff-macos/Sources/Views/Compare/DiffOverviewMap.swift
AboveDiff-macos/Sources/Views/Compare/FileDiffView.swift
AboveDiff-macos/Sources/Views/Compare/FileDiffWindowPresenter.swift
AboveDiff-macos/Tests/AboveDiffTests/DiffEngineTests.swift
```

## Replace completely

```text
AboveDiff-macos/Sources/Core/Diff/DiffEngine.swift
AboveDiff-macos/Sources/Views/Compare/FolderCompareView.swift
```

Do not merge those two replacement files line by line.

## Verify

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

Then:

```bash
swift run
```

Open Folder Compare and double-click one `Modified` non-directory file.
A separate File Diff window should open.
