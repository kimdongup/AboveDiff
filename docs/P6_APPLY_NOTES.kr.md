# P6 적용 노트

네이티브 3-way 병합 해결을 추가합니다.

## 새 Core 파일

```text
Sources/Core/Merge/
├── MergeDecision.swift
├── MergeResult.swift
└── ThreeWayMergeEngine.swift
```

## 새 State 파일

```text
Sources/State/Compare/
└── ThreeWayMergeState.swift
```

## 새 Views

```text
Sources/Views/Compare/
├── MergeDecisionGutter.swift
├── MergeResultPane.swift
├── ConflictNavigator.swift
├── ThreeWayMergeView.swift
└── ThreeWayMergeWindowPresenter.swift
```

## 새 테스트

```text
Tests/AboveDiffTests/
└── ThreeWayMergeEngineTests.swift
```

기존 파일을 교체할 필요는 없습니다.

## 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

## 수동 실행

```swift
ThreeWayMergeWindowPresenter.open(
    localURL: localURL,
    baseURL: baseURL,
    remoteURL: remoteURL
)
```

예상 동작:
- 충돌하지 않는 변경은 자동 병합
- 충돌은 미해결 상태로 시작
- Use Local / Remote / Base
- Local→Remote / Remote→Local
- 편집 가능한 병합 결과
- 결과 저장
- 저장 전 미해결 충돌 경고
