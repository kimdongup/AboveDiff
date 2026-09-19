# P7A — Git Core + Compare

## New Core

```text
Sources/Core/Git/
├── GitCommandRunner.swift
├── GitRevision.swift
├── GitStatusItem.swift
├── GitRepositoryService.swift
├── GitBlobLoader.swift
└── GitCompareMaterializer.swift
```

## New State

```text
Sources/State/Git/
└── GitCompareState.swift
```

## New View/Launcher

```text
Sources/Views/Git/
└── GitCompareLauncher.swift
```

## New Tests

```text
Tests/AboveDiffTests/
├── GitRepositoryServiceTests.swift
└── GitBlobLoaderTests.swift
```

## Supported

- repository detection via `git rev-parse --show-toplevel`
- file status
- current branch
- Working Tree
- Index/Staged
- HEAD
- conflict stage 1(BASE)
- stage 2(OURS)
- stage 3(THEIRS)
- 2-way Git compare
- Git conflict materialization into 3-way merge

## Verify

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

P7B will add:
- proper Git menu enable/disable state
- merge result save directly back to working tree
- optional `git add`
- conflict-resolution completion flow
