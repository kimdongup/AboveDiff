# P3 Apply Notes

## New files

```text
fxfile-macos/Sources/Core/Diff/TextDocumentService.swift
fxfile-macos/Sources/Core/Diff/DiffEditOperation.swift
fxfile-macos/Sources/Core/Diff/DiffEditEngine.swift
fxfile-macos/Sources/State/Compare/EditableFileDiffState.swift
fxfile-macos/Sources/Views/Compare/EditableDiffTextPane.swift
fxfile-macos/Sources/Views/Compare/DiffActionGutter.swift
fxfile-macos/Tests/fxfileTests/DiffEditEngineTests.swift
fxfile-macos/Tests/fxfileTests/TextDocumentServiceTests.swift
```

## Replace completely

```text
fxfile-macos/Sources/Views/Compare/FileDiffView.swift
fxfile-macos/Sources/Views/Compare/FileDiffWindowPresenter.swift
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

P3 manual checks:
- open Folder Compare
- double-click a Modified text file
- edit left and right text
- dirty dot appears
- Save Left/Save Right/Save All work
- Previous/Next still work
- gutter arrows copy current change between panes
- after applying a change, diff recalculates
