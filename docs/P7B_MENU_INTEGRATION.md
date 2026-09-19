# P7B menu integration

P7B adds `GitMenuState`, which should be owned by the App/Commands layer.

When the active selected file changes:

```swift
gitMenuState.inspect(
    selectedURL: selectedFile?.url
)
```

Then command availability:

```swift
Button("Compare Working Tree with HEAD") {
    guard let url = gitMenuState.selectedURL else { return }
    GitCompareLauncher.compareWorkingTreeWithHEAD(fileURL: url)
}
.disabled(
    !gitMenuState.capabilities.canCompareWorkingTreeWithHEAD
)

Button("Compare Staged with HEAD") {
    guard let url = gitMenuState.selectedURL else { return }
    GitCompareLauncher.compareStagedWithHEAD(fileURL: url)
}
.disabled(
    !gitMenuState.capabilities.canCompareStagedWithHEAD
)

Button("Compare Working Tree with Staged") {
    guard let url = gitMenuState.selectedURL else { return }
    GitCompareLauncher.compareWorkingTreeWithStaged(fileURL: url)
}
.disabled(
    !gitMenuState.capabilities.canCompareWorkingTreeWithStaged
)

Button("Resolve Git Conflict…") {
    guard let url = gitMenuState.selectedURL else { return }
    GitCompareLauncher.resolveConflict(fileURL: url)
}
.disabled(
    !gitMenuState.capabilities.canResolveConflict
)
```

The exact active-pane selection hook should use the existing FX File pane selection mechanism.
Do not duplicate pane-selection state inside the Git subsystem.
