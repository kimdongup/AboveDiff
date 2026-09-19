# P1 패치 안내

## 1. AppState.swift에 새 ToolSheetType 케이스를 추가

`ToolSheetType`에 다음을 추가하세요:

```swift
case folderCompare(left: URL?, right: URL?)
```

`id` switch에 다음을 추가하세요:

```swift
case .folderCompare: return "folderCompare"
```

그 외 AppState 변경은 필요하지 않습니다.

---

## 2. MainWindow.swift에 새 sheet 케이스를 추가

`.sheet(item: $appState.activeToolSheet) { sheetType in switch sheetType { ... } }` 안에
다음을 추가하세요:

```swift
case .folderCompare(let left, let right):
    FolderCompareView(
        appState: appState,
        leftRoot: left,
        rightRoot: right
    )
```

---

## 3. ToolbarView.swift에 Compare Panes를 추가

`Power Tools Group` 안에서 Directory Sync 앞에 다음을 추가하세요:

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

## 4. 새 파일

경로를 유지한 채로 다음 새 파일을 복사하세요:

```text
Sources/State/Compare/FolderCompareState.swift
Sources/Views/Compare/CompareStatusBadge.swift
Sources/Views/Compare/FolderCompareView.swift
```

Package.swift 수정은 필요하지 않습니다.

---

## 5. 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

그런 다음 실행하세요:

```bash
swift run
```

예상 결과:
- 툴바에 `Compare Panes`가 포함됨
- 클릭하면 Folder Compare가 열림
- left/right 루트의 기본값은 현재 두 창
- Smart/Metadata/Content 모드를 선택할 수 있음
- 상태 필터가 동작함
- Copy Left → Right / Copy Right → Left가 해당 행에서 동작함
- 수정된 파일을 더블클릭하면 P2 placeholder 상태가 표시됨
