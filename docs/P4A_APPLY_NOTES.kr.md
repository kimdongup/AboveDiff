# P4A 적용 노트

이것은 첫 번째 P4 구현 슬라이스입니다:
- 빈 줄 무시
- regex 텍스트 필터
- sync point
- diff 옵션 UI
- 정규화/원본 줄 매핑

## 새 파일

```text
AboveDiff-macos/Sources/Core/Diff/DiffFilter.swift
AboveDiff-macos/Sources/Core/Diff/DiffSyncPoint.swift
AboveDiff-macos/Sources/Core/Diff/TextNormalizer.swift
AboveDiff-macos/Sources/Views/Compare/DiffOptionsSheet.swift
AboveDiff-macos/Tests/AboveDiffTests/TextNormalizerTests.swift
AboveDiff-macos/Tests/AboveDiffTests/DiffOptionsTests.swift
```

## 완전히 교체

```text
AboveDiff-macos/Sources/Core/Diff/DiffEngine.swift
AboveDiff-macos/Sources/State/Compare/EditableFileDiffState.swift
AboveDiff-macos/Sources/Views/Compare/FileDiffView.swift
```

## 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

그런 다음 `swift run`을 실행하고, File Diff를 연 뒤 Options를 확인하세요:
- Ignore blank lines
- Regex filter
- Sync point

P4A가 통과한 뒤, P4B는 디렉터리 파일 이름 필터,
취소, 캐시, 대용량 파일 가드를 추가합니다.
