# P7A 메뉴 연결

현재 선택 파일을 얻는 코드가 `appState.leftPane.selectedFiles.first`
및 `rightPane` 구조라면 Tools 메뉴에 다음 식으로 연결할 수 있습니다.

```swift
Divider()

Button("Compare Git Working Tree with HEAD") {
    guard let file = appState.activePane.selectedFiles.first,
          !file.isDirectory else {
        return
    }

    GitCompareLauncher.compareWorkingTreeWithHEAD(
        fileURL: file.url
    )
}

Button("Compare Git Staged with HEAD") {
    guard let file = appState.activePane.selectedFiles.first,
          !file.isDirectory else {
        return
    }

    GitCompareLauncher.compareStagedWithHEAD(
        fileURL: file.url
    )
}

Button("Compare Git Working Tree with Staged") {
    guard let file = appState.activePane.selectedFiles.first,
          !file.isDirectory else {
        return
    }

    GitCompareLauncher.compareWorkingTreeWithStaged(
        fileURL: file.url
    )
}

Button("Resolve Git Conflict…") {
    guard let file = appState.activePane.selectedFiles.first,
          !file.isDirectory else {
        return
    }

    GitCompareLauncher.resolveConflict(
        fileURL: file.url
    )
}
```

`activePane`가 현재 AppState API에 없다면,
기존 Toolbar/Command 코드에서 쓰는 "현재 pane" 선택 방식을 그대로 사용하세요.

P7B에서 Git 메뉴 활성/비활성 상태를 자동 계산하도록 연결합니다.
