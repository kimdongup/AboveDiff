# P8B

## 새 파일

Core:
- Sources/Core/Diff/TextFileGuard.swift

State:
- Sources/State/Compare/FileDiffGuardState.swift

Views:
- Sources/Views/Compare/CompareWindowRegistry.swift

Tests:
- Tests/AboveDiffTests/TextFileGuardTests.swift

Docs:
- MELD_INTEGRATION_ARCHITECTURE.md
- MELD_INTEGRATION_USER_GUIDE.md
- P8_RELEASE_CHECKLIST.md

## 교체

- Sources/Views/Compare/FileDiffWindowPresenter.swift
- Sources/Views/Compare/ThreeWayDiffWindowPresenter.swift
- Sources/Views/Compare/ThreeWayMergeWindowPresenter.swift
- Sources/Views/Compare/ThreeWayMergeView.swift
- Sources/Views/Git/GitConflictMergeWindowPresenter.swift
- Sources/Views/Git/GitConflictMergeView.swift

## 추가 항목

- 중복 창 재사용
- Dock/앞으로 가져오기 활성화 동작
- 병합 소스 pane의 스크롤 동기화
- 바이너리/과대 텍스트 파일 가드 기본 구성 요소
- 아키텍처 문서
- 사용자 가이드
- 릴리스 체크리스트

## 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test

swift build -c release
```

수동:
- 같은 파일 diff를 두 번 열기 → 기존 창이 앞으로 와야 함
- 비교 창을 최소화한 뒤 같은 비교를 실행 → 복원되어야 함
- Three-Way Merge 소스 pane 동기화 스크롤
- Git 충돌 소스 pane 동기화 스크롤
