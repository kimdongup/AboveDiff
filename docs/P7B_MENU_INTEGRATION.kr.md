# P7B 메뉴 통합

P7B는 `GitMenuState`를 추가하며, 이는 App/Commands 계층이 소유해야 합니다.

현재 선택된 파일이 바뀌면:

```swift
gitMenuState.inspect(
    selectedURL: selectedFile?.url
)
```

이후 명령 활성 여부:

```swift
Button("Compare Working Tree with HEAD") {
    guard let url = gitMenuState.selectedURL else { return }
    GitCompareLauncher.compareWorkingTreeWithHEAD(fileURL: url)
}
.disabled(
    !gitMenuState.capabilities.canCompareWorkingTreeWithHEAD
)

Button("Compare Staged with HEAD") {
    guard let url = gitMenuState.selectedURL else { return }
    GitCompareLauncher.compareStagedWithHEAD(fileURL: url)
}
.disabled(
    !gitMenuState.capabilities.canCompareStagedWithHEAD
)

Button("Compare Working Tree with Staged") {
    guard let url = gitMenuState.selectedURL else { return }
    GitCompareLauncher.compareWorkingTreeWithStaged(fileURL: url)
}
.disabled(
    !gitMenuState.capabilities.canCompareWorkingTreeWithStaged
)

Button("Resolve Git Conflict…") {
    guard let url = gitMenuState.selectedURL else { return }
    GitCompareLauncher.resolveConflict(fileURL: url)
}
.disabled(
    !gitMenuState.capabilities.canResolveConflict
)
```

정확한 active-pane 선택 훅은 기존 AboveDiff pane 선택 메커니즘을 사용해야 합니다.
Git 서브시스템 안에 pane 선택 상태를 중복하지 마세요.
