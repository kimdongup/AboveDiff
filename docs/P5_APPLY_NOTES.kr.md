# P5 적용 노트

네이티브 3-way 비교를 추가합니다:

```text
LOCAL | BASE | REMOTE
```

분류:
- equal
- localOnly
- remoteOnly
- sameChange
- conflict

## 새 파일

```text
AboveDiff-macos/Sources/Core/Diff3/ThreeWayDiffChunk.swift
AboveDiff-macos/Sources/Core/Diff3/ThreeWayDiffResult.swift
AboveDiff-macos/Sources/Core/Diff3/ThreeWayDiffOptions.swift
AboveDiff-macos/Sources/Core/Diff3/ThreeWayDiffEngine.swift

AboveDiff-macos/Sources/State/Compare/ThreeWayDiffState.swift

AboveDiff-macos/Sources/Views/Compare/ThreeWayTextPane.swift
AboveDiff-macos/Sources/Views/Compare/ThreeWayOverviewMap.swift
AboveDiff-macos/Sources/Views/Compare/ThreeWayDiffView.swift
AboveDiff-macos/Sources/Views/Compare/ThreeWayDiffWindowPresenter.swift

AboveDiff-macos/Tests/AboveDiffTests/ThreeWayDiffEngineTests.swift
```

초기 P5 구현에서는 기존 소스 파일을 교체할 필요가 없습니다.

## 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

## 임시 수동 실행

메뉴 연결이 추가될 때까지 다음을 호출하세요:

```swift
ThreeWayDiffWindowPresenter.open(
    localURL: localURL,
    baseURL: baseURL,
    remoteURL: remoteURL
)
```

P6는 이 엔진 위에 실제 merge resolver를 구축합니다.
