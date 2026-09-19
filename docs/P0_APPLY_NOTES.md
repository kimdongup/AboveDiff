# P0 Apply Notes

Copy the contents of this bundle into the repository root, preserving paths.

Then run:

```bash
cd AboveDiff-macos
swift test
```

Important:
- `Sources/Core/Compare`, `Sources/Core/Directory`, `Sources/Core/Diff`,
  and `Sources/State/Compare` are new directories.
- `Sources/Core/DirectorySyncEngine.swift` is a replacement compatibility facade.
- `Sources/Views/Tools/DirectorySyncSheet.swift` is replaced so the View no longer
  calls the Core engine directly.
- `Package.swift` does not require changes because each module target already
  points at the parent source directory recursively.
