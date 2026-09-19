# P1 patch instructions

## 1. Add a new ToolSheetType case in AppState.swift

In `ToolSheetType` add:

```swift
case folderCompare(left: URL?, right: URL?)
```

In the `id` switch add:

```swift
case .folderCompare: return "folderCompare"
```

No other AppState change is required.

---

## 2. Add a new sheet case in MainWindow.swift

Inside `.sheet(item: $appState.activeToolSheet) { sheetType in switch sheetType { ... } }`
add:

```swift
case .folderCompare(let left, let right):
    FolderCompareView(
        appState: appState,
        leftRoot: left,
        rightRoot: right
    )
```

---

## 3. Add Compare Panes to ToolbarView.swift

Inside the `Power Tools Group`, before Directory Sync, add:

```swift
Button(action: {
    appState.activeToolSheet = .folderCompare(
        left: appState.leftPane.currentURL,
        right: appState.rightPane.currentURL
    )
}) {
    Label("Compare Panes", systemImage: "rectangle.split.2x1")
}
.help("Compare current left and right folders")
.disabled(!appState.dualPaneEnabled)
```

---

## 4. New files

Copy these new files preserving paths:

```text
Sources/State/Compare/FolderCompareState.swift
Sources/Views/Compare/CompareStatusBadge.swift
Sources/Views/Compare/FolderCompareView.swift
```

No Package.swift modification is required.

---

## 5. Verify

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

Then run:

```bash
swift run
```

Expected:
- toolbar contains `Compare Panes`
- clicking it opens Folder Compare
- left/right roots default to the two current panes
- Smart/Metadata/Content modes are selectable
- status filters work
- Copy Left → Right / Copy Right → Left work for applicable rows
- double-clicking a modified file shows the P2 placeholder status
