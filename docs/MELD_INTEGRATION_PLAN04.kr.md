# MELD_INTEGRATION_PLAN04.md

## 범위

P7: Git 통합
P8: 마무리 / UX / 성능 / 회귀 / 릴리스 준비

기준:
- P0~P6 테스트 통과
- Core → State → View 구조 유지
- Git CLI 호출은 Core/Service 계층에 격리
- View에서 직접 Process/git 실행 금지
- 기존 Folder Compare / File Diff / Three-Way Diff / Merge 회귀 금지

---

# P7 — Git 통합

## 목표

AboveDiff 내부에서 Git 작업 중 필요한 비교/병합 진입점을 제공한다.

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
- 현재 브랜치
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
- revisions 로드
- 2-way diff 열기

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

- working tree와 HEAD 비교
- staged와 HEAD 비교
- working tree와 staged 비교
- Git 충돌 해결…

선택 파일이 없거나 Git repo가 아니면 비활성화.

---

## P7 충돌 매핑

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
- repo root 탐지
- 수정된 파일
- staged file
- untracked file
- HEAD blob 로드
- index blob 로드
- conflict stage 1/2/3 로드
- 저장소가 아닌 경우의 오류
- cancellation
- 공백/유니코드 경로

---

# P8 — 마무리

## 목표

Meld 통합 기능을 실제 제품 수준으로 마감한다.

---

## P8 UX

### 비교 진입점 정리

Tools 메뉴:

- 폴더 비교…
- 선택한 파일 비교
- Three-Way 비교…
- Three-Way Merge…
- Git 비교…
- Git 충돌 해결…

### 단축키 정리

충돌 없는 범위에서 단축키 통일.

### 윈도우 생명주기

모든 별도 NSWindow:
- Dock 재활성화
- 앞으로 가져오기
- 중복 윈도우 정책
- close 시 retain 해제

### 오류 UX

Core 오류를 View가 직접 해석하지 않도록
State에서 사용자에게 보이는 메시지로 변환.

---

## P8 Diff UX

- 동기화 스크롤
- 현재 변경을 양쪽에서 동시에 스크롤
- 줄 번호 gutter
- 변경 연결선
- 키보드 탐색
- 다음/이전 conflict
- 찾기
- 줄바꿈 토글
- 글꼴 크기
- 대용량 파일 모드 명확화

---

## P8 Merge UX

- conflict 마커 선택적 내보내기
- resolved/unresolved 필터
- 결정 이력
- undo/redo 호환
- 저장 대상 명확화
- 덮어쓰기 확인
- encoding 유지

---

## P8 성능

- 전 구간에 cancellation 적용
- 디렉터리 비교 배칭
- diff cache eviction 검토
- 큰 텍스트의 점진적 highlight
- 바이너리 파일 가드
- 최대 파일 크기 설정 가능
- Task.detached 범위 점검
- MainActor blocking 제거

---

## P8 테스트

회귀 테스트:
- P0~P7 전체

추가:
- UI에 독립적인 state 테스트
- 대용량 파일
- 바이너리
- cancellation
- cache
- Git fixture
- 유니코드
- CRLF/LF
- 빈 파일
- 한 줄 파일
- 매우 긴 줄

---

## P8 문서

추가 문서:

MELD_INTEGRATION_ARCHITECTURE.md
- Core / State / View 의존성
- 비교 엔진
- 병합 엔진
- Git 통합
- 윈도우 아키텍처

MELD_INTEGRATION_USER_GUIDE.md
- Folder Compare
- File Diff
- 필터
- 동기화 지점
- 3-way 비교
- 병합
- Git 충돌 해결

---

## P8 릴리스 체크리스트

- swift test 전체 통과
- 릴리스 빌드 통과
- 경고 점검
- macOS deployment target 확인
- Intel/Apple Silicon 확인
- 앱 크기 확인
- Python/GTK 런타임 의존성 없음
- 중복 소스 파일 없음
- 실수로 남은 debug print 없음
- 메뉴 로컬라이제이션
- 접근성 레이블
- 키보드 탐색

---

# P7 완료 기준

- Git repo 탐지
- working tree / index / HEAD 비교
- Git conflict stage 1/2/3 로드
- Three-Way Merge 연결
- working tree에 저장
- 선택적 git add
- 테스트 통과

# P8 완료 기준

- 동기화 스크롤
- 줄 번호 / 탐색 UX
- 성능 가드
- 바이너리 처리
- 윈도우 생명주기 정리
- 전체 회귀 테스트
- 릴리스 빌드
- 아키텍처/사용자 가이드
- 외부 Meld 런타임 의존성 없음

---

# 구현 순서

P7:
1. GitCommandRunner
2. GitRepositoryService
3. GitBlobLoader
4. Git status model
5. GitCompareState
6. GitConflictState
7. Git 비교 UI
8. conflict → ThreeWayMerge 연결
9. 테스트

P8:
1. 동기화 스크롤
2. 줄 번호 gutter
3. 윈도우 생명주기
4. 바이너리 / 대용량 파일 가드
5. 성능 정리
6. state 테스트
7. 아키텍처 문서
8. 사용자 가이드
9. 릴리스 체크리스트

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
