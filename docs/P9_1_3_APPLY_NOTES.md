# P9.1-P9.3 Apply Notes

Current GitHub repository:
`kimdongup/AboveDiff`

GitHub connector write access is unavailable, so apply this patch locally.

## Replace
- AboveDiff-macos/Package.swift

## Add
- AboveDiff-macos/Sources/Core/Git/MergeTool/GitMergeToolArguments.swift
- AboveDiff-macos/Sources/Core/Git/MergeTool/GitMergeToolExitStatus.swift
- AboveDiff-macos/Sources/Core/Git/MergeTool/MergeToolSession.swift
- AboveDiff-macos/Sources/CLI/AboveDiffCLI.swift
- AboveDiff-macos/Tests/AboveDiffTests/GitMergeToolArgumentsTests.swift
- AboveDiff-macos/Tests/AboveDiffTests/MergeToolSessionTests.swift
- docs/MELD_INTEGRATION_PLAN05.md

## Verify

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos

rm -rf .build
swift test

swift run abovediff --help
swift run abovediff --version
```

Expected:

```text
abovediff 1.0.0
```

P9.1-P9.3 intentionally do not yet launch the GUI. A valid `--mergetool`
invocation creates a session request and returns `internalError` until
P9.4-P9.7 implement GUI handoff and session completion.
