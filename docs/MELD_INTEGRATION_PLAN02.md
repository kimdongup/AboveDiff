# MELD_INTEGRATION_PLAN02.md

## 0. 범위

이 문서는 P0~P2 완료 후 진행하는 **P3~P4** 구현 계획이다.

- P3: Editable Diff + Save + Undo/Redo + Change Block Apply
- P4: Filters + Ignore Blank Lines + Sync Points + Performance Hardening

기준:
- P0~P2 테스트 통과
- UI → State → Core 의존 방향 유지
- `fxfileCore`는 SwiftUI/AppKit 비의존
- View에서 파일 시스템/merge 로직 직접 수행 금지

---

# 1. P3 목표

현재 P2의 File Diff는 read-only이다.

P3에서 다음을 추가한다.

1. 좌/우 문서 편집 가능
2. 변경 내용 저장
3. Undo / Redo
4. Change block 단위 좌→우 / 우→좌 적용
5. 현재 change block 선택 및 이동
6. dirty state 표시
7. 저장 전 외부 변경 감지 기반 마련
8. diff 재계산 debounce

P3의 핵심은 "편집 UI"와 "merge 적용 로직"을 분리하는 것이다.

---

# 2. P3 아키텍처

```text
Views
  ├─ FileDiffView
  ├─ EditableDiffTextPane
  ├─ DiffActionGutter
  └─ DiffOverviewMap
        ↓
State
  └─ EditableFileDiffState
        ↓
Core
  ├─ DiffEngine
  ├─ DiffEditOperation
  ├─ DiffEditEngine
  └─ TextDocumentService
```

주의:
- NSTextView 편집 이벤트는 View에서 발생하지만,
  실제 문서 내용 state 반영은 `EditableFileDiffState`를 통해 수행한다.
- change block copy/replace는 Core `DiffEditEngine`이 문자열 단위로 처리한다.
- View에서 String range 계산 금지.

---

# 3. P3 Core 신규 파일

## 3.1 `DiffEditOperation.swift`

```swift
public enum DiffSide: Sendable {
    case left
    case right
}

public enum DiffEditOperationKind: Sendable {
    case replaceTargetWithSource
    case deleteTargetRange
}

public struct DiffEditOperation: Sendable {
    let sourceSide: DiffSide
    let targetSide: DiffSide
    let chunkID: Int
}
```

---

## 3.2 `DiffEditEngine.swift`

책임:
- 현재 `DiffResult`
- 현재 left/right text
- 선택 chunk
- 적용 방향

을 입력받아 새 text를 반환.

API 예:

```swift
public protocol DiffEditing: Sendable {
    func apply(
        chunk: DiffChunk,
        from source: DiffSide,
        leftText: String,
        rightText: String
    ) throws -> DiffEditResult
}
```

출력:

```swift
public struct DiffEditResult: Sendable {
    let leftText: String
    let rightText: String
}
```

중요:
- NSTextView range와 무관
- line range 기반
- UI callback 없음

---

## 3.3 `TextDocumentService.swift`

책임:
- text load
- encoding detect
- save
- atomic write
- optional backup
- modification timestamp 조회

P2의 `FileDiffState.readText()`를 여기로 이동.

이렇게 하면 State가 직접 Data(contentsOf:)를 하지 않는다.

---

# 4. P3 State

## 신규 `EditableFileDiffState.swift`

상태:

```text
leftURL
rightURL

leftText
rightText

leftSavedText
rightSavedText

leftDirty
rightDirty

result
currentChangeIndex

isLoading
isSaving
isReDiffing
errorMessage
```

명령:

```text
load()
updateLeftText(_:)
updateRightText(_:)

applyCurrentLeftToRight()
applyCurrentRightToLeft()

saveLeft()
saveRight()
saveAll()

nextChange()
previousChange()
```

Undo/Redo:
- AppKit NSTextView의 native undo manager를 사용
- State는 undo stack을 직접 구현하지 않는다
- 단, undo/redo 후 변경 text를 State로 전달하여 diff 재계산

---

# 5. P3 View

## 5.1 `EditableDiffTextPane.swift`

P2 `DiffTextPane` 교체.

요구:
- `NSTextView.isEditable = true`
- text change delegate
- native undoManager
- line highlighting
- current chunk scroll
- monospaced font
- find bar 유지

View → State callback:

```swift
onTextChanged: (String) -> Void
```

---

## 5.2 `DiffActionGutter.swift`

Meld 스타일 중앙 action gutter.

2-way 기준:

```text
LEFT      GUTTER      RIGHT

AAA                    AAA
BBB       →  ←         CCC
DDD                    DDD
```

버튼:
- Left → Right
- Right → Left

현재 chunk 위치에 action 표시.

P3에서는 delete-only chunk도 동일 API로 처리.

---

## 5.3 `FileDiffView.swift`

상단 toolbar 추가:

```text
Save Left
Save Right
Save All

Undo
Redo

Previous
Next
```

dirty 표시:

```text
● file.swift
```

또는 title에 `*`.

---

# 6. P3 Re-diff 전략

문자 입력마다 즉시 전체 diff를 수행하면 비효율적이다.

State에서 debounce:

```text
text change
  ↓
250~400 ms debounce
  ↓
background diff
  ↓
MainActor result update
```

초기값:
- 300ms

파일이 매우 큰 경우:
- 향후 incremental diff 가능
- P3에서는 full re-diff로 시작

---

# 7. P3 저장 전략

기본:
- atomic write
- 기존 encoding 최대한 유지
- 실패 시 기존 파일 보존

초기 P3:
- UTF-8/UTF-16/Latin-1 load
- 저장은 loaded encoding 유지
- 불가능하면 명시적 error

P4 이후:
- encoding selector 검토

---

# 8. P3 테스트

신규:

```text
DiffEditEngineTests.swift
TextDocumentServiceTests.swift
EditableFileDiffStateTests.swift
```

필수:
- insert chunk left→right
- insert chunk right→left
- delete chunk apply
- replace chunk apply
- first chunk
- last chunk
- Unicode
- CRLF
- dirty tracking
- save clears dirty
- failed save retains dirty
- re-diff after edit

---

# 9. P4 목표

Meld의 실사용성을 좌우하는 비교 옵션을 추가한다.

1. ignore blank lines
2. text regex filters
3. file/folder filters
4. sync points
5. large-file performance
6. binary handling 개선
7. compare cancellation
8. cache

---

# 10. P4 Core 신규/확장

## 10.1 `TextNormalizer.swift`

책임:
- line ending normalize
- ignore blank lines
- optional whitespace normalization
- regex filters

API:

```swift
public protocol TextNormalizing: Sendable {
    func normalize(
        text: String,
        options: TextNormalizationOptions
    ) throws -> NormalizedText
}
```

중요:
원본 text와 normalized line mapping을 같이 유지해야 한다.

```text
normalized line
  ↔
original line
```

그래야 UI highlight가 정확하다.

---

## 10.2 `DiffFilter.swift`

```swift
public struct RegexTextFilter: Sendable, Hashable {
    let pattern: String
    let replacement: String
    let isEnabled: Bool
}
```

P4에서는:
- regex 제거/치환
- filter enable/disable
- invalid regex validation

---

## 10.3 Directory filter

확장:

```swift
DirectoryCompareOptions
```

추가:
- filename include glob
- filename exclude glob
- regex
- extension filter

---

## 10.4 Sync Points

사용자가 좌/우 특정 라인을 수동으로 대응시킴.

Core:

```swift
public struct DiffSyncPoint: Sendable, Hashable {
    let leftLine: Int
    let rightLine: Int
}
```

`DiffOptions`:

```swift
var syncPoints: [DiffSyncPoint]
```

엔진은 구간별 diff 수행 후 concatenate.

---

# 11. P4 Performance

## 11.1 Cancellation

긴 directory compare / diff는 cancel 가능해야 함.

Foundation Task cancellation을 Core API에 전달.

초기:
- periodic `Task.isCancelled`

## 11.2 Cache

Directory compare content cache key:

```text
path
size
mtime
comparison options hash
```

Diff cache key:

```text
left content hash
right content hash
options hash
```

## 11.3 Large file guard

예:
- 10 MB 이상 텍스트
- 100k lines 이상

시:
- syntax highlighting 최소화
- overview map downsample
- diff warning 표시

---

# 12. P4 State/View

State 옵션:

```text
ignoreBlankLines
textFilters
syncPoints
```

View:
- Compare Options sheet
- filter list editor
- sync point add/remove

UI는 Core regex 직접 실행 금지.

---

# 13. P3~P4 파일 구조

```text
Sources/Core/Diff/
├── DiffEngine.swift
├── DiffEditOperation.swift
├── DiffEditEngine.swift
├── TextDocumentService.swift
├── TextNormalizer.swift
├── DiffFilter.swift
└── DiffSyncPoint.swift

Sources/State/Compare/
├── FileDiffState.swift
└── EditableFileDiffState.swift

Sources/Views/Compare/
├── FileDiffView.swift
├── EditableDiffTextPane.swift
├── DiffActionGutter.swift
├── DiffOverviewMap.swift
└── DiffOptionsSheet.swift
```

---

# 14. P3 Definition of Done

- [ ] 좌/우 편집 가능
- [ ] native Undo/Redo
- [ ] Save Left/Right/All
- [ ] dirty state
- [ ] change block left→right
- [ ] change block right→left
- [ ] change 적용 후 자동 re-diff
- [ ] View에서 문자열 merge 로직 없음
- [ ] Core에서 SwiftUI/AppKit import 없음
- [ ] 관련 unit tests 통과

---

# 15. P4 Definition of Done

- [ ] ignore blank lines
- [ ] regex text filters
- [ ] invalid regex 처리
- [ ] filename filters
- [ ] sync points
- [ ] cancellation
- [ ] large-file guard
- [ ] cache
- [ ] filter/sync point unit tests
- [ ] 기존 P0~P3 regression 없음

---

# 16. 구현 순서

P3:

1. `TextDocumentService.swift`
2. `DiffEditOperation.swift`
3. `DiffEditEngine.swift`
4. `EditableFileDiffState.swift`
5. `EditableDiffTextPane.swift`
6. `DiffActionGutter.swift`
7. `FileDiffView.swift` 교체
8. tests

P4:

1. `TextNormalizer.swift`
2. `DiffFilter.swift`
3. `DiffSyncPoint.swift`
4. `DiffEngine` 옵션 확장
5. `DirectoryCompareOptions` 필터 확장
6. State 옵션 추가
7. Diff Options UI
8. cancellation/cache/large-file guard
9. tests

---

# 17. 브랜치

권장:

```text
feature/meld-p3-p4
```

P3 완료 시 중간 commit:

```text
feat(diff): add editable two-way diff and block apply
```

P4 완료 시:

```text
feat(diff): add filters sync points and performance controls
```

P4 완료 후 P5~P6 전용:
- `MELD_INTEGRATION_PLAN03.md`
