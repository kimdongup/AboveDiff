# P9.8 적용 노트

## 교체
- AboveDiff-macos/CLI/Sources/abovediff/main.swift

## 추가
- AboveDiff-macos/Sources/Core/Git/MergeTool/GitMergetoolConfiguration.swift
- AboveDiff-macos/Tests/AboveDiffTests/GitMergetoolConfigurationTests.swift
- scripts/install-abovediff-mergetool.sh
- scripts/uninstall-abovediff-mergetool.sh
- docs/P9_REAL_WORLD_TEST.md

## 검증

GUI:

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
swift test
swift build
```

CLI:

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos/CLI
swift build -c release
swift run abovediff --version
```

설치:

```bash
cd /Users/kimdongup/Bazel/AboveDiff
chmod +x scripts/install-abovediff-mergetool.sh
./scripts/install-abovediff-mergetool.sh
```

그런 다음 `docs/P9_REAL_WORLD_TEST.md`를 따르세요.
