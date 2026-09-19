# P7B

## New files

Core:
- Sources/Core/Git/GitConflictService.swift
- Sources/Core/Git/GitSelectionCapabilities.swift

State:
- Sources/State/Git/GitMenuState.swift
- Sources/State/Git/GitConflictResolutionState.swift

Views:
- Sources/Views/Git/GitConflictMergeView.swift
- Sources/Views/Git/GitConflictMergeWindowPresenter.swift

Tests:
- Tests/AboveDiffTests/GitSelectionCapabilitiesTests.swift
- Tests/AboveDiffTests/GitConflictServiceTests.swift

## Replace

- Sources/Views/Git/GitCompareLauncher.swift

## Git conflict flow

1. Select conflicted working-tree file.
2. Resolve Git Conflict…
3. AboveDiff loads:
   - stage 2 = OURS / LOCAL
   - stage 1 = BASE
   - stage 3 = THEIRS / REMOTE
4. Resolve all conflicts.
5. Save to Working Tree.
6. Stage as Resolved.
7. Only step 6 executes `git add`.

No automatic staging is performed.

## Verify

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```
