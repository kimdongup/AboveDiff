# P3 적용 노트

## 새 파일

```text
AboveDiff-macos/Sources/Core/Diff/TextDocumentService.swift
AboveDiff-macos/Sources/Core/Diff/DiffEditOperation.swift
AboveDiff-macos/Sources/Core/Diff/DiffEditEngine.swift
AboveDiff-macos/Sources/State/Compare/EditableFileDiffState.swift
AboveDiff-macos/Sources/Views/Compare/EditableDiffTextPane.swift
AboveDiff-macos/Sources/Views/Compare/DiffActionGutter.swift
AboveDiff-macos/Tests/AboveDiffTests/DiffEditEngineTests.swift
AboveDiff-macos/Tests/AboveDiffTests/TextDocumentServiceTests.swift
```

## 완전히 교체

```text
AboveDiff-macos/Sources/Views/Compare/FileDiffView.swift
AboveDiff-macos/Sources/Views/Compare/FileDiffWindowPresenter.swift
```

이 두 교체 파일을 줄 단위로 병합하지 마세요.

## 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

그런 다음:

```bash
swift run
```

P3 수동 확인:
- Folder Compare를 엽니다
- Modified 텍스트 파일을 더블클릭합니다
- 왼쪽과 오른쪽 텍스트를 편집합니다
- dirty 점이 나타납니다
- Save Left/Save Right/Save All이 동작합니다
- Previous/Next가 계속 동작합니다
- gutter 화살표가 현재 변경을 창 간에 복사합니다
- 변경을 적용한 뒤 diff가 다시 계산됩니다
