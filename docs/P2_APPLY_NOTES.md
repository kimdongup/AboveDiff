# P2 Apply Notes

## New files

```text
fxfile-macos/Sources/State/Compare/FileDiffState.swift
fxfile-macos/Sources/Views/Compare/DiffTextPane.swift
fxfile-macos/Sources/Views/Compare/DiffOverviewMap.swift
fxfile-macos/Sources/Views/Compare/FileDiffView.swift
fxfile-macos/Sources/Views/Compare/FileDiffWindowPresenter.swift
fxfile-macos/Tests/fxfileTests/DiffEngineTests.swift
```

## Replace completely

```text
fxfile-macos/Sources/Core/Diff/DiffEngine.swift
fxfile-macos/Sources/Views/Compare/FolderCompareView.swift
```

Do not merge those two replacement files line by line.

## Verify

```bash
cd /Users/kimdongup/Bazel/fxfile/fxfile-macos
rm -rf .build
swift test
```

Then:

```bash
swift run
```

Open Folder Compare and double-click one `Modified` non-directory file.
A separate File Diff window should open.
