# P7B

## 새 파일

Core:
- Sources/Core/Git/GitConflictService.swift
- Sources/Core/Git/GitSelectionCapabilities.swift

State:
- Sources/State/Git/GitMenuState.swift
- Sources/State/Git/GitConflictResolutionState.swift

Views:
- Sources/Views/Git/GitConflictMergeView.swift
- Sources/Views/Git/GitConflictMergeWindowPresenter.swift

Tests:
- Tests/AboveDiffTests/GitSelectionCapabilitiesTests.swift
- Tests/AboveDiffTests/GitConflictServiceTests.swift

## 교체

- Sources/Views/Git/GitCompareLauncher.swift

## Git 충돌 흐름

1. 충돌이 있는 working-tree 파일을 선택합니다.
2. Resolve Git Conflict…
3. AboveDiff가 다음을 로드합니다:
   - stage 2 = OURS / LOCAL
   - stage 1 = BASE
   - stage 3 = THEIRS / REMOTE
4. 모든 충돌을 해결합니다.
5. Save to Working Tree.
6. Stage as Resolved.
7. 6단계만 `git add`를 실행합니다.

자동 스테이징은 수행되지 않습니다.

## 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```
