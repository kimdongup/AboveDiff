# P9.1-P9.3 build fix

## Cause

The first P9 patch added `AboveDiffCLI` as a second executable target to the
main GUI package. With the current Xcode/SwiftPM explicit-module build,
the `abovediff` build caused the GUI executable target to be dependency-scanned
at the same time, and the scan failed while resolving `AboveDiffState` /
`AboveDiffViews`.

The CLI does not need those modules, so the clean solution is to isolate the CLI
into its own nested Swift package.

## 1. Restore

Replace:

```text
AboveDiff-macos/Package.swift
```

with the supplied file. It is the same package graph as the current GitHub main
version and contains no CLI target.

## 2. Delete old CLI file

Delete:

```text
AboveDiff-macos/Sources/CLI/AboveDiffCLI.swift
```

If `Sources/CLI` becomes empty, remove that directory too.

## 3. Add separate CLI package

Add:

```text
AboveDiff-macos/CLI/Package.swift
AboveDiff-macos/CLI/Sources/abovediff/main.swift
```

The CLI package depends only on the parent package's `AboveDiffCore` product.

## 4. Keep P9 Core files

Do NOT delete:

```text
AboveDiff-macos/Sources/Core/Git/MergeTool/GitMergeToolArguments.swift
AboveDiff-macos/Sources/Core/Git/MergeTool/GitMergeToolExitStatus.swift
AboveDiff-macos/Sources/Core/Git/MergeTool/MergeToolSession.swift
```

Keep their tests too.

## 5. Verify GUI package

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos

rm -rf .build
swift test
swift build
```

## 6. Verify CLI separately

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos/CLI

rm -rf .build
swift build

swift run abovediff --help
swift run abovediff --version
```

Expected:

```text
abovediff 1.0.0
```

## 7. Find CLI binary

```bash
swift build -c release --show-bin-path
```

The `abovediff` binary in that directory is the executable we will package or
symlink into `/usr/local/bin/abovediff` in P9.8.
