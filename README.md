# AboveDiff

<p align="center">
  <b>Native macOS file manager with built-in compare and merge</b>
</p>

---

## Overview

**AboveDiff** is a native macOS application for browsing files, comparing folders and text, and resolving three-way / Git conflicts. It is built with Swift and SwiftUI / AppKit for macOS 13+.

This repository contains:

1. **`AboveDiff-macos`**: Native macOS application (Swift 6 / SwiftUI / AppKit).
2. **`docs/`**: Compare / merge architecture, plans, and apply notes.

---

## Features

### File management
- Dual-pane layout (`Cmd + 2`) with horizontal and vertical split. Switch focus with `Tab`.
- Multi-tab browsing (`Cmd + T` / `Cmd + W`) with per-tab history.
- Address bar, breadcrumbs, sidebar locations, and bookmarks.
- Finder integration: Quick Look (`Space`), open (`Return`), copy/move to the other pane (`Cmd + 5` / `Cmd + 6`).

### Compare and merge
- Folder compare (smart / metadata / content).
- Two-way file diff with synchronized scroll, line numbers, filters, and sync points.
- Three-way compare and merge (LOCAL / BASE / REMOTE).
- Git compare (working tree, index, HEAD) and conflict resolution (OURS / BASE / THEIRS).

### Built-in tools
- Batch rename, checksum, split/join, directory sync, search, scrap basket, and batch item creation.
- English and Korean UI.

---

## Building and running

### Prerequisites
- macOS 13.0 or higher
- Xcode or Command Line Tools (`swift`, `clang`)

### One-click build and package
```bash
./build-macos.sh
```
This will:
1. Run the test suite (`swift test`).
2. Compile the release binary with Swift Package Manager.
3. Generate a signed `AboveDiff.app` bundle in `dist/AboveDiff.app`.

### Launch
```bash
open dist/AboveDiff.app
```

### Swift Package Manager
```bash
cd AboveDiff-macos
swift run
```

### Tests
```bash
cd AboveDiff-macos
swift test
```

---

## Git mergetool

The CLI mergetool name is `abovediff`:

```bash
git config --global merge.tool abovediff
git config --global mergetool.abovediff.trustExitCode true
```

Future CLI:

```bash
abovediff --mergetool \
  --base "$BASE" \
  --local "$LOCAL" \
  --remote "$REMOTE" \
  --merged "$MERGED"
```

---

## Project structure

```
.
├── AboveDiff-macos/              # Native Swift/SwiftUI app
│   ├── Package.swift
│   ├── Sources/
│   │   ├── App/                  # AboveDiffApp entry and menu bar
│   │   ├── Core/                 # File system, compare, diff, merge, Git
│   │   ├── State/                # Observable app and compare state
│   │   ├── Views/                # Main window, panes, compare UI, tools
│   │   └── Localization/
│   ├── Tests/AboveDiffTests/
│   └── Resources/
├── build-macos.sh
├── docs/
└── README.md
```

Swift modules: `AboveDiffCore`, `AboveDiffLocalization`, `AboveDiffState`, `AboveDiffViews`.

---

## License

This project is licensed under the GPLv3 License — see the [LICENSE](LICENSE) file for details.
