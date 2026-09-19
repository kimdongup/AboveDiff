# P8A

Adds:
- synchronized vertical scrolling
- line number rulers
- sync-scroll toggle
- reusable scroll group shared by 2-way and 3-way panes

## New files

```text
Sources/Views/Compare/
├── SynchronizedScrollGroup.swift
└── LineNumberRulerView.swift
```

## Replace completely

```text
Sources/Views/Compare/EditableDiffTextPane.swift
Sources/Views/Compare/ThreeWayTextPane.swift
Sources/Views/Compare/FileDiffView.swift
Sources/Views/Compare/ThreeWayDiffView.swift
```

ThreeWayMergeView and GitConflictMergeView automatically benefit from
line numbers through ThreeWayTextPane. Their manual scrolling remains
independent in P8A; P8B can share the same scroll group there if desired.

## Verify

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
swift run
```

Manual:
- File Diff: scroll left → right follows
- disable Sync Scroll → panes scroll independently
- line numbers visible in both panes
- Three-Way Compare: all 3 panes synchronize
- current change navigation still scrolls to the selected change
