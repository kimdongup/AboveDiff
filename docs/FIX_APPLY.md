# P0 Fix 1

This patch fixes the build log errors after the first P0 merge.

## Critical cause

The repository still compiled the old `Sources/Core/DirectorySyncEngine.swift`,
which only exposed:

```swift
compareDirectories(... compareChecksum: Bool ...)
```

but `DirectoryCompareState.swift` calls the new overload:

```swift
compareDirectories(... comparisonMode: FileComparisonMode ...)
```

Therefore `DirectorySyncEngine.swift` must be REPLACED, not merged line-by-line.

## Files to replace

Replace these three files completely:

1. `AboveDiff-macos/Sources/Core/DirectorySyncEngine.swift`
2. `AboveDiff-macos/Sources/Core/Directory/DirectorySyncExecutor.swift`
3. `AboveDiff-macos/Sources/Core/Directory/DirectorySyncPlanner.swift`

Then clean and test:

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

Optional verification before build:

```bash
grep -n "comparisonMode" Sources/Core/DirectorySyncEngine.swift
```

It must show the new overload.
