# P8 Release Checklist

## Build
- [ ] `swift test`
- [ ] debug build
- [ ] release build
- [ ] warnings reviewed

## Architecture
- [ ] Views do not directly execute Git/process engines
- [ ] Core imports no SwiftUI/AppKit
- [ ] no duplicate source files
- [ ] no temporary debug prints

## Compare
- [ ] Folder Compare
- [ ] File Diff
- [ ] synchronized scroll
- [ ] line numbers
- [ ] regex filters
- [ ] sync points
- [ ] large file warning/guard
- [ ] binary text guard

## Three-Way
- [ ] compare
- [ ] conflict navigation
- [ ] merge decisions
- [ ] merged result save
- [ ] synchronized source panes

## Git
- [ ] repo detection
- [ ] HEAD/index/working-tree compare
- [ ] conflict stage 1/2/3 load
- [ ] save to working tree
- [ ] explicit Stage as Resolved
- [ ] Git menu disabled outside repositories

## Window lifecycle
- [ ] duplicate compare windows reuse existing window
- [ ] minimized window restores
- [ ] Dock activation brings compare window forward
- [ ] close removes window from registry

## Release
- [ ] Apple Silicon build
- [ ] Intel build if supported by deployment pipeline
- [ ] no Python/GTK runtime dependency
- [ ] localization pass
- [ ] accessibility labels
- [ ] keyboard navigation
