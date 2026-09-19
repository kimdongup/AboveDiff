# AboveDiff 비교 / 병합 아키텍처

## 의존성 방향

```text
Views
  ↓
State
  ↓
Core
```

Core는 SwiftUI/AppKit을 import하지 않습니다.

## Core 엔진

- DirectoryCompareEngine
- LineDiffEngine
- ThreeWayDiffEngine
- ThreeWayMergeEngine
- GitRepositoryService
- GitBlobLoader
- GitConflictService

## 비교 모드

### 폴더 비교
두 디렉터리, 재귀/비재귀, metadata/content/smart.

### 파일 Diff
블록 복사와 저장이 가능한 편집 가능한 2-way 텍스트 비교.

### 3-way Diff
LOCAL / BASE / REMOTE 읽기 전용 비교.

### 3-way Merge
병합 결정과 편집 가능한 결과를 포함한 LOCAL / BASE / REMOTE.

### Git Conflict
Git 스테이지 매핑:
- stage 1 → BASE
- stage 2 → OURS / LOCAL
- stage 3 → THEIRS / REMOTE

저장과 스테이징은 별도 작업입니다.

## UI 인프라

- SynchronizedScrollGroup
- LineNumberRulerView
- CompareWindowRegistry

## 윈도우 정책

동일한 비교 키는 중복 창을 열지 않고 기존 창을 재사용합니다.
창을 닫으면 레지스트리에서 제거됩니다.

## 런타임 의존성

Python, GTK, Meld runtime, GtkSourceView 의존성은 필요하지 않습니다.
