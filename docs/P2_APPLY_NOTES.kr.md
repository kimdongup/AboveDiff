# P2 적용 노트

## 새 파일

```text
AboveDiff-macos/Sources/State/Compare/FileDiffState.swift
AboveDiff-macos/Sources/Views/Compare/DiffTextPane.swift
AboveDiff-macos/Sources/Views/Compare/DiffOverviewMap.swift
AboveDiff-macos/Sources/Views/Compare/FileDiffView.swift
AboveDiff-macos/Sources/Views/Compare/FileDiffWindowPresenter.swift
AboveDiff-macos/Tests/AboveDiffTests/DiffEngineTests.swift
```

## 완전히 교체

```text
AboveDiff-macos/Sources/Core/Diff/DiffEngine.swift
AboveDiff-macos/Sources/Views/Compare/FolderCompareView.swift
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

Folder Compare를 열고 `Modified`인 디렉터리가 아닌 파일 하나를 더블클릭하세요.
별도의 File Diff 창이 열려야 합니다.
