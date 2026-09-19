# P8A

추가 항목:
- 수직 스크롤 동기화
- 줄 번호 눈금자
- 동기화 스크롤 토글
- 2-way와 3-way pane이 공유하는 재사용 가능한 스크롤 그룹

## 새 파일

```text
Sources/Views/Compare/
├── SynchronizedScrollGroup.swift
└── LineNumberRulerView.swift
```

## 전체 교체

```text
Sources/Views/Compare/EditableDiffTextPane.swift
Sources/Views/Compare/ThreeWayTextPane.swift
Sources/Views/Compare/FileDiffView.swift
Sources/Views/Compare/ThreeWayDiffView.swift
```

ThreeWayMergeView와 GitConflictMergeView는 ThreeWayTextPane을 통해
줄 번호를 자동으로 사용합니다. P8A에서 이들의 수동 스크롤은
독립적으로 유지됩니다. 필요하면 P8B에서 같은 스크롤 그룹을 공유할 수 있습니다.

## 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
swift run
```

수동:
- File Diff: 왼쪽을 스크롤하면 오른쪽이 따라감
- Sync Scroll 끄기 → pane이 독립적으로 스크롤
- 양쪽 pane에 줄 번호가 표시됨
- Three-Way Compare: 3개 pane 모두 동기화
- 현재 변경 탐색이 선택한 변경으로 계속 스크롤됨
