# AboveDiff Compare / Merge Architecture

## Dependency direction

```text
Views
  ↓
State
  ↓
Core
```

Core does not import SwiftUI/AppKit.

## Core engines

- DirectoryCompareEngine
- LineDiffEngine
- ThreeWayDiffEngine
- ThreeWayMergeEngine
- GitRepositoryService
- GitBlobLoader
- GitConflictService

## Compare modes

### Folder Compare
Two directories, recursive/non-recursive, metadata/content/smart.

### File Diff
Editable 2-way text comparison with block copy and save.

### Three-Way Diff
LOCAL / BASE / REMOTE read-only comparison.

### Three-Way Merge
LOCAL / BASE / REMOTE with merge decisions and editable result.

### Git Conflict
Git stage mapping:
- stage 1 → BASE
- stage 2 → OURS / LOCAL
- stage 3 → THEIRS / REMOTE

Saving and staging are separate operations.

## UI infrastructure

- SynchronizedScrollGroup
- LineNumberRulerView
- CompareWindowRegistry

## Window policy

The same comparison key reuses an existing window instead of opening duplicates.
Closing the window removes it from the registry.

## Runtime dependencies

No Python, GTK, Meld runtime, or GtkSourceView dependency is required.
