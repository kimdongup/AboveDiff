# fxfileApp.swift menu patch

`fxfileApp.swift`의 `CommandMenu("Tools")` 안에서 기존 Compare 메뉴들 근처에 아래 두 버튼을 추가하세요.

```swift
Divider()

Button("Three-Way Compare…") {
    ThreeWayCompareLauncher.openCompare()
}
.keyboardShortcut(
    "3",
    modifiers: [.command, .option]
)

Button("Three-Way Merge…") {
    ThreeWayCompareLauncher.openMerge()
}
.keyboardShortcut(
    "m",
    modifiers: [.command, .option, .shift]
)
```

필요 import:

```swift
import fxfileViews
```

이미 `fxfileViews`를 import하고 있으면 추가할 필요 없습니다.

권장 Tools 순서:

```text
Compare Folders
Compare Selected Files
Three-Way Compare…
Three-Way Merge…
────────────
Directory Sync
...
```

이 방식은 기존 `AppState.ToolSheetType`를 변경하지 않습니다.
3-way compare/merge는 별도 NSWindow를 열기 때문에 ToolSheet enum에 넣지 않는 편이 안전합니다.
