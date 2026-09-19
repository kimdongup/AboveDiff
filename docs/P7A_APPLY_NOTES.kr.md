# P7A — Git Core + 비교

## 새 Core

```text
Sources/Core/Git/
├── GitCommandRunner.swift
├── GitRevision.swift
├── GitStatusItem.swift
├── GitRepositoryService.swift
├── GitBlobLoader.swift
└── GitCompareMaterializer.swift
```

## 새 State

```text
Sources/State/Git/
└── GitCompareState.swift
```

## 새 View/Launcher

```text
Sources/Views/Git/
└── GitCompareLauncher.swift
```

## 새 테스트

```text
Tests/AboveDiffTests/
├── GitRepositoryServiceTests.swift
└── GitBlobLoaderTests.swift
```

## 지원 항목

- `git rev-parse --show-toplevel`를 통한 저장소 탐지
- 파일 상태
- 현재 브랜치
- Working Tree
- Index/Staged
- HEAD
- 충돌 stage 1(BASE)
- stage 2(OURS)
- stage 3(THEIRS)
- 2-way Git 비교
- Git 충돌을 3-way 병합으로 구체화

## 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

P7B에서 추가할 항목:
- Git 메뉴 활성/비활성 상태 처리
- 병합 결과를 working tree에 직접 저장
- 선택적 `git add`
- 충돌 해결 완료 흐름
