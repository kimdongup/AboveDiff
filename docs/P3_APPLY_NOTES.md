# P3 Apply Notes

## New files

```text
AboveDiff-macos/Sources/Core/Diff/TextDocumentService.swift
AboveDiff-macos/Sources/Core/Diff/DiffEditOperation.swift
AboveDiff-macos/Sources/Core/Diff/DiffEditEngine.swift
AboveDiff-macos/Sources/State/Compare/EditableFileDiffState.swift
AboveDiff-macos/Sources/Views/Compare/EditableDiffTextPane.swift
AboveDiff-macos/Sources/Views/Compare/DiffActionGutter.swift
AboveDiff-macos/Tests/AboveDiffTests/DiffEditEngineTests.swift
AboveDiff-macos/Tests/AboveDiffTests/TextDocumentServiceTests.swift
```

## Replace completely

```text
AboveDiff-macos/Sources/Views/Compare/FileDiffView.swift
AboveDiff-macos/Sources/Views/Compare/FileDiffWindowPresenter.swift
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

P3 manual checks:
- open Folder Compare
- double-click a Modified text file
- edit left and right text
- dirty dot appears
- Save Left/Save Right/Save All work
- Previous/Next still work
- gutter arrows copy current change between panes
- after applying a change, diff recalculates
