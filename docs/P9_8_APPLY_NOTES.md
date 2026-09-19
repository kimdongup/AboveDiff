# P9.8 Apply Notes

## Replace
- AboveDiff-macos/CLI/Sources/abovediff/main.swift

## Add
- AboveDiff-macos/Sources/Core/Git/MergeTool/GitMergetoolConfiguration.swift
- AboveDiff-macos/Tests/AboveDiffTests/GitMergetoolConfigurationTests.swift
- scripts/install-abovediff-mergetool.sh
- scripts/uninstall-abovediff-mergetool.sh
- docs/P9_REAL_WORLD_TEST.md

## Verify

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

Install:

```bash
cd /Users/kimdongup/Bazel/AboveDiff
chmod +x scripts/install-abovediff-mergetool.sh
./scripts/install-abovediff-mergetool.sh
```

Then follow `docs/P9_REAL_WORLD_TEST.md`.
