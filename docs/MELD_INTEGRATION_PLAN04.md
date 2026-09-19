# MELD_INTEGRATION_PLAN04.md

## 범위

P7: Git Integration
P8: Finalization / UX / Performance / Regression / Release Readiness

기준:
- P0~P6 테스트 통과
- Core → State → View 구조 유지
- Git CLI 호출은 Core/Service 계층에 격리
- View에서 직접 Process/git 실행 금지
- 기존 Folder Compare / File Diff / Three-Way Diff / Merge 회귀 금지

---

# P7 — Git Integration

## 목표

FX File 내부에서 Git 작업 중 필요한 비교/병합 진입점을 제공한다.

지원 대상:
- working tree vs HEAD
- staged vs HEAD
- working tree vs staged
- conflict 상태의 ours / base / theirs
- 선택 파일의 Git diff
- Git merge conflict → Three-Way Merge 연결

---

## P7 Core 구조

Sources/Core/Git/
- GitRepositoryService.swift
- GitCommandRunner.swift
- GitStatusItem.swift
- GitRevision.swift
- GitBlobLoader.swift
- GitConflictResolver.swift

### GitCommandRunner

책임:
- /usr/bin/git 또는 PATH의 git 실행
- stdout/stderr 수집
- exit code 확인
- cancellation 지원
- shell interpolation 금지
- Process.arguments 사용

### GitRepositoryService

기능:
- repository root 찾기
- git status --porcelain=v2
- tracked/untracked/conflicted 판별
- current branch
- selected file path의 repository relative path 계산

### GitBlobLoader

revision에서 파일 내용을 가져온다.

예:
- HEAD:path
- :path (index)
- :1:path (merge base)
- :2:path (ours)
- :3:path (theirs)

반환:
- String text
- binary 여부
- encoding/failure 정보

### GitRevision

예:
- workingTree
- index
- head
- mergeBase
- ours
- theirs
- custom(String)

---

## P7 State

Sources/State/Git/
- GitCompareState.swift
- GitConflictState.swift

GitCompareState:
- repositoryRoot
- selectedFile
- leftRevision
- rightRevision
- load revisions
- open 2-way diff

GitConflictState:
- conflicted file
- base/ours/theirs 로드
- ThreeWayMergeState로 연결
- unresolved/resolved 상태

---

## P7 View

Sources/Views/Git/
- GitCompareSheet.swift
- GitConflictSheet.swift
- GitStatusBadge.swift

메뉴:

Tools 또는 Git 메뉴:

- Compare Working Tree with HEAD
- Compare Staged with HEAD
- Compare Working Tree with Staged
- Resolve Git Conflict…

선택 파일이 없거나 Git repo가 아니면 disabled.

---

## P7 Conflict Mapping

Git merge stage:

- stage 1 → BASE
- stage 2 → LOCAL / OURS
- stage 3 → REMOTE / THEIRS

Three-Way Merge 연결:

LOCAL = ours
BASE = stage 1
REMOTE = theirs

최종 저장 대상:
working tree file

저장 후:
- 사용자가 명시적으로 선택할 때만 git add 수행
- 자동 stage 금지

---

## P7 테스트

GitCommandRunnerTests
GitRepositoryServiceTests
GitBlobLoaderTests
GitConflictMappingTests

fixture repo를 temp directory에 생성하여 테스트.

필수:
- repo root detection
- modified file
- staged file
- untracked file
- HEAD blob load
- index blob load
- conflict stage 1/2/3 load
- non-repository error
- cancellation
- spaces/unicode path

---

# P8 — Finalization

## 목표

Meld 통합 기능을 실제 제품 수준으로 마감한다.

---

## P8 UX

### Compare entry points 정리

Tools 메뉴:

- Compare Folders…
- Compare Selected Files
- Three-Way Compare…
- Three-Way Merge…
- Git Compare…
- Resolve Git Conflict…

### Shortcut 정리

충돌 없는 범위에서 단축키 통일.

### Window lifecycle

모든 별도 NSWindow:
- Dock 재활성화
- bring-to-front
- duplicate window 정책
- close 시 retain 해제

### Error UX

Core error를 View가 직접 해석하지 않도록
State에서 user-facing message로 변환.

---

## P8 Diff UX

- synchronized scrolling
- 현재 change 양쪽 동시 scroll
- line number gutter
- change connector
- keyboard navigation
- next/previous conflict
- find
- wrap toggle
- font size
- large-file mode 명확화

---

## P8 Merge UX

- conflict marker optional export
- resolved/unresolved filter
- decision history
- undo/redo compatibility
- save target 명확화
- overwrite confirmation
- encoding 유지

---

## P8 Performance

- cancellation 전 구간 적용
- directory compare batching
- diff cache eviction 검토
- large text incremental highlight
- binary file guard
- max file size configurable
- Task.detached 범위 점검
- MainActor blocking 제거

---

## P8 Tests

회귀 테스트:
- P0~P7 전체

추가:
- UI-independent state tests
- large file
- binary
- cancellation
- cache
- Git fixture
- unicode
- CRLF/LF
- empty files
- one-line files
- very long lines

---

## P8 Documentation

추가 문서:

MELD_INTEGRATION_ARCHITECTURE.md
- Core / State / View dependency
- compare engines
- merge engine
- Git integration
- window architecture

MELD_INTEGRATION_USER_GUIDE.md
- Folder Compare
- File Diff
- filters
- sync points
- 3-way compare
- merge
- Git conflict resolve

---

## P8 Release checklist

- swift test 전체 통과
- release build 통과
- warnings 점검
- macOS deployment target 확인
- Intel/Apple Silicon 확인
- app size 확인
- no Python/GTK runtime dependency
- no duplicate source files
- no accidental debug print
- menu localization
- accessibility labels
- keyboard navigation

---

# P7 Definition of Done

- Git repo 탐지
- working tree / index / HEAD 비교
- Git conflict stage 1/2/3 로드
- Three-Way Merge 연결
- save to working tree
- optional git add
- 테스트 통과

# P8 Definition of Done

- synchronized scrolling
- line number / navigation UX
- performance guard
- binary handling
- window lifecycle 정리
- 전체 회귀 테스트
- release build
- architecture/user guide
- no external Meld runtime dependency

---

# 구현 순서

P7:
1. GitCommandRunner
2. GitRepositoryService
3. GitBlobLoader
4. Git status model
5. GitCompareState
6. GitConflictState
7. Git compare UI
8. conflict → ThreeWayMerge 연결
9. tests

P8:
1. synchronized scrolling
2. line number gutter
3. window lifecycle
4. binary / large file guards
5. performance cleanup
6. state tests
7. architecture docs
8. user guide
9. release checklist

---

# 브랜치

feature/meld-p7-p8

추천 commit:

feat(git): add git repository and revision services
feat(git): integrate git file comparison
feat(git): connect merge conflicts to three-way merge
feat(diff): add synchronized scrolling and navigation polish
perf(diff): improve large-file and cancellation handling
docs(compare): add meld integration architecture and user guide
