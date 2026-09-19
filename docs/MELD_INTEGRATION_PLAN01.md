# MELD_INTEGRATION_PLAN01.md

## 0. 목적

이 문서는 `AboveDiff` macOS 네이티브 앱에 Meld의 핵심 비교 기능을 **Swift/SwiftUI/AppKit 네이티브 구조로 흡수**하기 위한 P0~P2 실행 계획이다.

대상 저장소:
- `kimdongup/AboveDiff`
- 기준 브랜치: `main`
- 작업 브랜치: `feature/meld-p0-p2`

이번 계획의 범위:
- P0: 비교/동기화 로직의 계층 분리 및 현재 DirectorySync 정리
- P1: 2-way Folder Compare
- P2: 2-way File Diff read-only
- P3~P8은 P0~P2 완료/검증 후 `MELD_INTEGRATION_PLAN02.md`부터 후속 계획으로 작성

---

## 1. 최우선 아키텍처 원칙

### 1.1 UI와 로직의 강제 분리

의존 방향은 반드시 아래 한 방향만 허용한다.

```text
Views
  ↓
State / ViewModel
  ↓
Core
```

금지:

```text
Views → Core Engine 직접 호출
Core → SwiftUI
Core → AppKit
Core → View/Window 상태 참조
```

### 1.2 모듈별 책임

#### Core
순수 로직 계층.

허용:
- Foundation
- 파일 입출력
- diff/merge 알고리즘
- 비교 결과 모델
- 필터/정규화
- 동기화 plan 생성/실행

금지:
- SwiftUI
- AppKit
- `@Published`
- 화면 색상/문구
- sheet/window 처리

#### State
화면 상태 및 Core orchestration.

책임:
- Core 엔진 호출
- async task 수명
- progress
- selection
- filter state
- compare session
- error presentation용 상태

#### Views
표현 전용.

책임:
- 사용자 입력 전달
- State 관찰
- 결과 렌더링

금지:
- 직접 파일 비교
- 직접 checksum 계산
- 직접 diff 생성
- `DirectorySyncEngine.shared` 등 Core singleton 직접 호출

---

## 2. 현재 코드 분석 요약

### 2.1 현재 macOS 구조

```text
AboveDiff-macos/
├── Sources/
│   ├── App/
│   │   └── AboveDiffApp.swift
│   ├── Core/
│   │   ├── BatchRenameEngine.swift
│   │   ├── ChecksumService.swift
│   │   ├── DirectorySyncEngine.swift
│   │   ├── FileItem.swift
│   │   ├── FileSearchEngine.swift
│   │   ├── FileSplitJoinEngine.swift
│   │   └── FileSystemService.swift
│   ├── State/
│   │   ├── AppState.swift
│   │   └── PaneState.swift
│   └── Views/
│       ├── MainWindow.swift
│       ├── PaneView.swift
│       ├── FileTableView.swift
│       ├── ToolbarView.swift
│       └── Tools/
│           └── DirectorySyncSheet.swift
└── Tests/AboveDiffTests/
    ├── DirectorySyncTests.swift
    └── StateTests.swift
```

### 2.2 현재 발견된 구조적 문제

`DirectorySyncSheet.swift`가 UI 코드 안에서 다음을 직접 수행한다.

```swift
DirectorySyncEngine.shared.compareDirectories(...)
DirectorySyncEngine.shared.executeSync(...)
```

이는 앞으로 Diff/Merge 기능이 커질 때 UI와 로직의 결합도를 크게 높인다.

P0에서 이 직접 의존을 제거한다.

### 2.3 기존 DirectorySyncEngine의 비교 한계

현재 동일 판정 핵심은 대략 다음 조건이다.

```swift
abs(mtime difference) < 2 seconds && size equal
```

따라서:
- 내용이 달라도 크기와 mtime이 같으면 `.equal` 가능
- `compareChecksum` 파라미터가 존재하지만 실제 판정에 충분히 사용되지 않음
- binary/text 구분 없음
- blank-line/text filter 없음
- content compare mode가 명시적으로 분리되어 있지 않음

P0에서 비교 정책을 분리한다.

---

# P0 — Compare/Sync Core 정리

## 3. 목표

1. 기존 `DirectorySyncEngine`을 UI에서 완전히 분리한다.
2. "비교"와 "동기화 실행"을 분리한다.
3. 파일 비교 정책을 명시적 타입으로 분리한다.
4. 추후 Meld 스타일 Folder Compare와 File Diff가 공통 타입을 공유할 수 있게 만든다.

---

## 4. P0 신규 구조

```text
Sources/Core/
├── Compare/
│   ├── FileComparisonMode.swift
│   ├── FileContentComparator.swift
│   ├── CompareFilter.swift
│   └── ComparisonError.swift
│
├── Directory/
│   ├── DirectoryCompareEngine.swift
│   ├── DirectoryCompareItem.swift
│   ├── DirectoryCompareOptions.swift
│   ├── DirectorySyncPlanner.swift
│   └── DirectorySyncExecutor.swift
│
└── Diff/
    └── DiffEngine.swift
```

State:

```text
Sources/State/
├── AppState.swift
├── PaneState.swift
└── Compare/
    └── DirectoryCompareState.swift
```

Views:

```text
Sources/Views/
└── Compare/
    └── FolderCompareView.swift
```

P0에서는 기존 `DirectorySyncSheet`를 즉시 삭제하지 않는다.
호환을 유지한 상태에서 State 계층을 거치도록 바꾸고 P1에서 UI를 교체한다.

---

## 5. P0 파일별 작업

### 5.1 신규 `FileComparisonMode.swift`

```swift
public enum FileComparisonMode: Sendable {
    case metadata
    case content
    case smart
}
```

정의:

- `metadata`
  - size + mtime
  - 가장 빠름
- `content`
  - 실제 byte 비교
  - mtime 무시
- `smart`
  - metadata quick reject
  - 애매한 경우 content compare

기본값은 `.smart`.

### 5.2 신규 `FileContentComparator.swift`

책임:
- chunked byte comparison
- binary detection
- optional normalized text comparison
- 향후 ignore blank lines / text filter 확장

초기 API:

```swift
public protocol FileContentComparing: Sendable {
    func compare(
        _ lhs: URL,
        _ rhs: URL,
        options: FileContentCompareOptions
    ) throws -> FileContentComparison
}
```

### 5.3 신규 `DirectoryCompareEngine.swift`

비교 전용.

금지:
- copy
- move
- delete

입력:

```swift
DirectoryCompareRequest
```

출력:

```swift
[DirectoryCompareItem]
```

### 5.4 신규 `DirectorySyncPlanner.swift`

비교 결과에서 실행 계획을 생성.

```text
Compare result
    ↓
Sync policy
    ↓
SyncPlan
```

비교와 정책을 분리한다.

### 5.5 신규 `DirectorySyncExecutor.swift`

`SyncPlan`만 받아 실제 파일 작업 수행.

### 5.6 기존 `DirectorySyncEngine.swift`

P0 동안 facade로 유지.

```swift
@available(*, deprecated, message: "Use DirectoryCompareEngine + DirectorySyncPlanner + DirectorySyncExecutor")
```

기존 테스트를 깨지 않고 점진적으로 이전한다.

### 5.7 신규 `DirectoryCompareState.swift`

`@MainActor ObservableObject`

책임:
- sourceURL
- targetURL
- options
- compare results
- progress
- selected rows
- sync plan
- error
- loading state

View는 이 State만 사용한다.

### 5.8 `DirectorySyncSheet.swift`

P0 변경:
- Core import를 점차 제거
- `DirectoryCompareState`에 명령 전달
- Core Engine 직접 호출 금지

---

## 6. P0 테스트

신규:

```text
Tests/AboveDiffTests/
├── FileContentComparatorTests.swift
├── DirectoryCompareEngineTests.swift
├── DirectorySyncPlannerTests.swift
└── DirectorySyncExecutorTests.swift
```

필수 케이스:
- same size + same mtime + different content
- same content + different mtime
- empty files
- large files chunk compare
- binary files
- nested folders
- left only
- right only
- same
- modified
- permission/read failure
- smart mode
- metadata mode
- content mode

기존 `DirectorySyncTests.swift`는 facade compatibility test로 유지 후 차후 축소.

---

# P1 — 2-way Folder Compare

## 7. 목표

Meld 스타일의 폴더 비교 기능을 AboveDiff의 dual-pane workflow에 통합한다.

입력 기본값:

```text
leftPane.currentURL ↔ rightPane.currentURL
```

---

## 8. P1 사용자 흐름

Toolbar:

```text
Compare Panes
```

메뉴:

```text
Tools
 └─ Compare
     ├─ Compare Panes
     └─ Compare Selected Files
```

폴더 비교 화면:

```text
┌──────────────────────────────────────────────────────────┐
│ Left Root                  ↔             Right Root      │
├──────────────────────────────────────────────────────────┤
│ name/path    left info    status       right info        │
│ README.md    10 KB          =          10 KB             │
│ A.swift      12 KB          M          13 KB             │
│ old.txt       1 KB          ←          --                │
│ new.txt       --            →           1 KB             │
└──────────────────────────────────────────────────────────┘
```

초기 상태 분류:

```swift
same
modified
leftOnly
rightOnly
typeMismatch
error
```

sync action은 별도 표시한다.

---

## 9. P1 신규 파일

```text
Sources/State/Compare/
├── DirectoryCompareState.swift
└── CompareSelectionState.swift

Sources/Views/Compare/
├── FolderCompareView.swift
├── FolderCompareToolbar.swift
├── FolderCompareTable.swift
└── CompareStatusBadge.swift
```

View 파일은 Core engine을 import하지 않는 것을 목표로 한다.
필요한 display model은 State에서 제공한다.

---

## 10. P1 기능

필수:
- recursive
- show/hide equal
- show/hide left-only
- show/hide right-only
- show/hide modified
- hidden file policy
- metadata/content/smart comparison mode
- compare refresh
- row selection
- selected row copy left→right
- selected row copy right→left
- delete action은 기존 confirm 정책 재사용
- modified text file double-click → P2 File Diff

후속(P3 이후):
- text regex filters
- same-after-filter
- 3-way directory compare

---

# P2 — 2-way File Diff read-only

## 11. 목표

두 텍스트 파일을 편집 없이 비교한다.

P2에서는 merge/write를 하지 않는다.
읽기 전용 비교 화면과 diff navigation에 집중한다.

---

## 12. Core Diff 설계

신규:

```text
Sources/Core/Diff/
├── DiffEngine.swift
├── DiffDocument.swift
├── DiffChunk.swift
├── DiffOptions.swift
└── TextLineTokenizer.swift
```

단, 최초 commit에서는 `DiffEngine.swift`에 public API를 먼저 고정하고,
구현 안정화 후 파일을 분리할 수 있다.

---

## 13. DiffEngine API 원칙

### Core는 UI를 모른다.

잘못된 예:

```swift
DiffChunk {
    var color: Color
}
```

금지.

올바른 예:

```swift
DiffChunk {
    var kind: DiffKind
    var leftRange: Range<Int>
    var rightRange: Range<Int>
}
```

색상/아이콘은 View 계층에서 결정한다.

### 입력

```swift
DiffDocument
```

- URL
- text
- lines
- encoding metadata

### 출력

```swift
DiffResult
```

- chunks
- left line count
- right line count
- statistics

---

## 14. Diff 알고리즘 단계

P2 initial:
- line-based
- deterministic
- no UI dependency
- no file IO inside algorithm
- input is already decoded text/lines

P2 구현 후보:
1. Myers O(ND) — 최종 목표
2. 초기 correctness 구현 후 Myers 교체 가능

중요:
`DiffEngine` protocol과 `DiffResult` 모델을 먼저 고정하여 알고리즘 교체가 View/State에 영향을 주지 않게 한다.

---

## 15. P2 State

```text
Sources/State/Compare/
└── FileDiffState.swift
```

책임:

```text
URL loading
encoding detection
DiffEngine invocation
current difference index
next/previous navigation
scroll mapping data
error/loading state
```

---

## 16. P2 View

```text
Sources/Views/Compare/
├── FileDiffView.swift
├── DiffTextPane.swift
├── DiffGutterView.swift
└── DiffOverviewMap.swift
```

P2에서는 read-only.

텍스트 표시 구현:
- AppKit `NSTextView`
- SwiftUI `NSViewRepresentable`
- line number
- attributed range highlighting
- scroll synchronization

SwiftUI `TextEditor`는 사용하지 않는다.

---

## 17. P2 동기 스크롤 원칙

단순 scroll percentage 동기화 금지.

Diff chunk 기준 line mapping:

```text
left line
  ↓
chunk / equal region resolve
  ↓
right logical line
  ↓
right viewport
```

삽입/삭제 구간에서는 nearest stable anchor를 사용한다.

---

## 18. P2 테스트

신규:

```text
DiffEngineTests.swift
```

필수:
- empty ↔ empty
- empty ↔ one line
- equal files
- insertion
- deletion
- replacement
- multiple separated changes
- first line change
- last line change
- CRLF/LF normalization
- trailing newline difference policy
- Korean/Unicode
- large repeated lines
- deterministic result

---

# 19. AppState 통합 원칙

현재 `ToolSheetType` 중심 구조는 간단한 도구에는 적합하지만,
Compare Workspace는 장기적으로 sheet보다 독립 workspace/tab이 더 적합하다.

P0~P1:
- 기존 sheet 경로 호환 유지

P2:
- `CompareSession` 도입 검토

예:

```swift
public enum CompareSessionKind {
    case directory
    case file
}

public struct CompareSession: Identifiable {
    let id: UUID
    let kind: CompareSessionKind
}
```

P3부터 editable diff가 들어가면 반드시 sheet 의존을 제거하는 방향으로 이동한다.

---

# 20. 브랜치 전략

```text
main
 └─ feature/meld-p0-p2
      ├─ P0 commits
      ├─ P1 commits
      └─ P2 commits
```

P0~P2 완료 후:

```text
feature/meld-p0-p2
   ↓ PR / merge
main
```

다음 계획:

```text
main
 └─ feature/meld-p3-p4
```

그 다음:

```text
main
 └─ feature/meld-p5-p6
```

마지막:

```text
main
 └─ feature/meld-p7-p8
```

계획 문서:
- `MELD_INTEGRATION_PLAN01.md`: P0~P2
- `MELD_INTEGRATION_PLAN02.md`: P3~P4
- `MELD_INTEGRATION_PLAN03.md`: P5~P6
- `MELD_INTEGRATION_PLAN04.md`: P7~P8

각 계획 문서는 **직전 단계 구현 및 테스트 확인 후 작성**한다.

---

# 21. Commit 전략

예상:

```text
docs: add Meld integration plan for P0-P2

refactor(compare): introduce comparison policies and models

refactor(sync): split directory compare planning and execution

refactor(state): isolate directory compare orchestration from SwiftUI views

feat(compare): add native two-way folder compare workspace

feat(diff): add line-based DiffEngine core

feat(diff): add read-only two-way file diff state

feat(diff): add native AppKit-backed diff viewer

test(compare): cover content and directory comparison

test(diff): cover two-way line diff cases
```

---

# 22. P0~P2 Definition of Done

## P0
- [ ] View에서 `DirectorySyncEngine.shared` 직접 호출 없음
- [ ] compare / plan / execute 책임 분리
- [ ] metadata/content/smart 모드 존재
- [ ] same-size/same-mtime/different-content 테스트 통과
- [ ] 기존 sync tests 회귀 없음

## P1
- [ ] left/right pane folder compare 가능
- [ ] 상태 필터 가능
- [ ] content compare 가능
- [ ] copy direction action 가능
- [ ] UI에 비교 알고리즘 없음
- [ ] State가 Core 호출 담당

## P2
- [ ] two-way text diff 가능
- [ ] insertion/deletion/replacement 구분
- [ ] next/previous difference
- [ ] read-only
- [ ] synchronized scrolling
- [ ] overview map
- [ ] Core가 SwiftUI/AppKit 미참조
- [ ] DiffEngine unit tests 통과

---

# 23. P3~P8 예정 로드맵

P3:
- editable diff
- save
- undo/redo
- change block copy left↔right

P4:
- filters
- ignore blank lines
- regex text filters
- sync points
- performance hardening

P5:
- 3-way diff core
- LOCAL / BASE / REMOTE

P6:
- 3-way merge
- conflict resolver
- merge result document

P7:
- Git integration
- working tree / index / HEAD / branch compare

P8:
- Git conflict workflow
- stage 1/2/3 extraction
- resolve + save + stage integration

---

# 24. 첫 구현 진입점

P0 첫 코드 순서:

1. `DiffEngine.swift` public model/API 확정
2. `FileComparisonMode.swift`
3. `FileContentComparator.swift`
4. `DirectoryCompareItem.swift`
5. `DirectoryCompareEngine.swift`
6. `DirectorySyncPlanner.swift`
7. `DirectorySyncExecutor.swift`
8. 기존 `DirectorySyncEngine` facade화
9. `DirectoryCompareState.swift`
10. `DirectorySyncSheet` 직접 Core 호출 제거
11. tests

이 순서를 벗어나 UI부터 구현하지 않는다.
