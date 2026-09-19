# P4B 적용 노트

추가 사항:
- 1부터 시작하는 Sync Point UI
- 보이는 Sync Point 요약 마커
- Folder Compare include/exclude 파일 이름 필터
- glob 또는 regex 이름 필터링
- 비교 취소
- diff 결과 캐시
- 대용량 파일 가드

## 새 파일

```text
AboveDiff-macos/Sources/Core/Diff/DiffPerformance.swift
AboveDiff-macos/Sources/Core/Directory/DirectoryNameFilter.swift
AboveDiff-macos/Sources/Views/Compare/SyncPointSummaryBar.swift
AboveDiff-macos/Tests/AboveDiffTests/DirectoryNameFilterTests.swift
AboveDiff-macos/Tests/AboveDiffTests/DiffPerformanceTests.swift
```

## 완전히 교체

```text
AboveDiff-macos/Sources/Core/Diff/DiffEngine.swift
AboveDiff-macos/Sources/Core/Directory/DirectoryCompareOptions.swift
AboveDiff-macos/Sources/Core/Directory/DirectoryCompareEngine.swift
AboveDiff-macos/Sources/State/Compare/FolderCompareState.swift
AboveDiff-macos/Sources/Views/Compare/DiffOptionsSheet.swift
AboveDiff-macos/Sources/Views/Compare/FileDiffView.swift
AboveDiff-macos/Sources/Views/Compare/FolderCompareView.swift
```

## 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

그런 다음:
- Sync Point UI는 내부 인덱스 0에 대해 1번 줄을 표시해야 합니다
- 활성 sync point는 diff 위에 `L n ↔ R m`으로 나타납니다
- Folder Compare include/exclude 필터가 동작합니다
- Cancel이 긴 비교를 중지합니다
- 큰 문서는 성능 경고를 표시하고 줄 단위 하이라이트를 억제합니다
