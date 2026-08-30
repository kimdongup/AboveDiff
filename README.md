# fxfile (flyExplorer)

<p align="center">
  <b>Professional Multi-Tab & Dual-Pane File Manager for macOS</b>
</p>

---

## 🌟 Overview

**fxfile** (originally *flyExplorer*) is a fast, powerful, and versatile file manager featuring multi-tab browsing, dual-pane layout, directory tree navigation, and a comprehensive suite of power tools.

This repository contains:
1. **`fxfile-macos`**: A brand new **native macOS application** built with **Swift 6.2 + SwiftUI / AppKit**, designed specifically for modern macOS (Ventura, Sonoma, Sequoia+).
2. **`src/`**: The classic Windows C++ MFC source code.

---

## ✨ Features (macOS Native Edition)

### 🗂️ Core File Management
- **Dual-Pane Layout (`Cmd + 2`)**: Horizontal and Vertical split modes. Switch focus instantly between panes using `Tab`.
- **Multi-Tab Browsing (`Cmd + T` / `Cmd + W`)**: Independent tabs per pane with per-tab navigation history.
- **Smart Address & Breadcrumb Bar**: Clickable breadcrumb navigation and direct path editing.
- **Sidebar & Quick Locations**: Fast access to Home, Desktop, Documents, Downloads, Applications, Mounted Volumes, and custom Bookmarks.
- **Finder & macOS Integration**:
  - `Spacebar`: Native QuickLook preview.
  - `Return` / `Enter`: Open file with default application or enter directory.
  - `Cmd + 5`: Copy selected files to opposite pane.
  - `Cmd + 6`: Move selected files to opposite pane.
  - `Cmd + [` / `Cmd + ]`: Go back / forward in history.
  - `Cmd + Up`: Enclosing folder navigation.
  - `Cmd + Shift + .`: Toggle hidden files.
  - `F2 ~ F8`: Classic function keys toolbar (Rename, View, Edit, Copy, Move, New Folder, Delete).

### 🛠️ Built-in Power Tools
- **Batch Rename**: Rule-based renaming (Text find & replace, regex replacement with capture groups, prefix/suffix, sequential numbering with zero padding, case transformations, extension modifications) with live diff preview.
- **Checksum Calculator & Verifier**: CRC32 (IEEE 802.3), MD5, SHA-1, SHA-256, and SHA-512 hashing with file verification and `.sfv` export.
- **File Split & Join**: Split large files into chunked parts (`.001`, `.002`, ...) and rejoin them with checksum validation.
- **Directory Compare & Synchronize**: Recursive differential analysis (Missing, Newer, Modified, Equal) and directional/mirror/bidirectional syncing.
- **File Search**: Multi-criteria search by filename (wildcards/regex), size ranges, date ranges, and text content matching with line numbers.
- **File Scrap Basket (수집함)**: Collect files from different directories into a temporary workspace for batch actions.
- **Batch Item Creator**: Bulk create files and folders by pattern or line-by-line lists.
- **Multi-Language Support**: English and Korean (한국어) interface.

---

## 🚀 Building and Running on macOS

### Prerequisites
- macOS 13.0 or higher
- Xcode or Command Line Tools (`swift`, `clang`)

### Quick Start: One-Click Build & Package
Run the build script in the repository root:
```bash
./build-macos.sh
```
This will:
1. Run the entire test suite (`swift test`).
2. Compile the release binary with Swift Package Manager.
3. Generate a signed `fxfile.app` bundle in `dist/fxfile.app`.

### Launching the App
```bash
open dist/fxfile.app
```

### Running via Swift Package Manager
```bash
cd fxfile-macos
swift run
```

### Running Tests
```bash
cd fxfile-macos
swift test
```

---

## 📂 Project Structure

```
.
├── fxfile-macos/                 # macOS Native Swift/SwiftUI Port
│   ├── Package.swift             # SPM Manifest
│   ├── Sources/
│   │   ├── App/                  # SwiftUI App entry & MenuBar
│   │   ├── Core/                 # FileSystem, Checksum, BatchRename, SplitJoin, Sync, Search engines
│   │   ├── State/                # AppState & PaneState (Observable models)
│   │   ├── Views/                # MainWindow, PaneView, FileTableView, Sidebar, Toolbar
│   │   │   └── Tools/            # 8 Power Tool Dialog Sheets
│   │   └── Localization/         # English & Korean string tables
│   ├── Tests/                    # 58 comprehensive unit tests
│   └── Resources/                # Retina AppIcon.icns
├── build-macos.sh                # macOS build and packaging automation script
├── src/                          # Classic Windows C++ MFC Source Code
├── lib/                          # Windows third-party libraries
├── dist/                         # Distribution files and build output
└── README.md
```

---

## 📄 License

This project is licensed under the GPLv3 License - see the [LICENSE](LICENSE) file for details.
