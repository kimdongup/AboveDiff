# P9.1-P9.3 적용 노트

현재 GitHub 저장소:
`kimdongup/AboveDiff`

GitHub 커넥터 쓰기 권한이 없으므로, 이 패치를 로컬에서 적용하세요.

## 교체
- AboveDiff-macos/Package.swift

## 추가
- AboveDiff-macos/Sources/Core/Git/MergeTool/GitMergeToolArguments.swift
- AboveDiff-macos/Sources/Core/Git/MergeTool/GitMergeToolExitStatus.swift
- AboveDiff-macos/Sources/Core/Git/MergeTool/MergeToolSession.swift
- AboveDiff-macos/Sources/CLI/AboveDiffCLI.swift
- AboveDiff-macos/Tests/AboveDiffTests/GitMergeToolArgumentsTests.swift
- AboveDiff-macos/Tests/AboveDiffTests/MergeToolSessionTests.swift
- docs/MELD_INTEGRATION_PLAN05.md

## 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos

rm -rf .build
swift test

swift run abovediff --help
swift run abovediff --version
```

예상 결과:

```text
abovediff 1.0.0
```

P9.1-P9.3은 의도적으로 아직 GUI를 실행하지 않습니다. 유효한 `--mergetool`
호출은 세션 요청을 생성하고, P9.4-P9.7에서 GUI 핸드오프와 세션 완료가
구현될 때까지 `internalError`를 반환합니다.
