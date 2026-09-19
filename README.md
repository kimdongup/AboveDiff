<h1>
  <img src="assets/AboveDiffIcon.png" width="72" alt="AboveDiff icon" align="absmiddle">
  AboveDiff
</h1>

**Native diff, compare, merge, and Git conflict resolution for macOS.**

AboveDiff is a native macOS file manager and comparison tool designed for fast **2-way diff**, **3-way diff**, **folder comparison**, **merge conflict resolution**, and **Git mergetool integration**.

It provides a visual workflow for comparing files and directories, resolving conflicting versions, and merging changes without requiring Python, GTK, Meld, or other external GUI runtimes.

---

## Features

### File Diff

Compare two text files side by side.

* Line-by-line diff
* Insert / delete / replace highlighting
* Synchronized scrolling
* Line numbers
* Previous / next change navigation
* Overview map
* Editable left and right panes
* Copy individual change blocks between files
* Save Left / Right / All
* Native macOS Undo / Redo
* Large-file protection

---

### Three-Way Diff

Compare:

```text
LOCAL  |  BASE  |  REMOTE
```

AboveDiff classifies changes as:

```text
equal
localOnly
remoteOnly
sameChange
conflict
```

This makes it easy to understand how two versions evolved from a common base.

Features include:

* Three synchronized panes
* Conflict-only navigation
* Line numbers
* Change overview
* Conflict highlighting
* LOCAL / BASE / REMOTE visualization

---

### Three-Way Merge

Resolve conflicts interactively using:

```text
Use Local
Use Remote
Use Base
Local → Remote
Remote → Local
```

The merge result remains editable before saving.

Non-conflicting changes can be automatically merged, while unresolved conflicts are tracked separately.

---

### Folder Compare

Compare two directories recursively.

Comparison modes:

```text
Smart
Metadata
Content
```

Features:

* Same / Modified / Left Only / Right Only / Error filters
* Recursive comparison
* Hidden-file option
* Include / exclude filename filters
* Glob or regular-expression matching
* Copy Left → Right
* Copy Right → Left
* Open modified files directly in File Diff
* Cancel long-running comparisons

---

### Diff Filters

AboveDiff supports comparison-specific filtering.

#### Ignore blank lines

Blank lines can be excluded from comparison without modifying the displayed files.

#### Regex filters

Differences such as timestamps, generated IDs, or version strings can be normalized during comparison.

Example:

```text
Left:
timestamp=123456

Right:
timestamp=987654
```

Regex:

```regex
timestamp=\d+
```

Replacement:

```text
timestamp=<ignored>
```

The original text remains visible, while the normalized values are considered equal by the diff engine.

---

### Sync Points

For difficult files where automatic alignment is ambiguous, manual sync points can be specified.

Example:

```text
Left line 22 ↔ Right line 26
```

This tells AboveDiff to use those lines as an alignment anchor.

Sync point line numbers are displayed using normal **1-based numbering**.

---

## Git Integration

AboveDiff understands Git working-tree, staged, HEAD, and conflict states.

Supported comparisons include:

```text
Working Tree ↔ HEAD
Staged       ↔ HEAD
Working Tree ↔ Staged
```

Git repositories are detected using:

```bash
git rev-parse --show-toplevel
```

rather than relying only on the presence of a `.git` directory.

This also supports Git worktrees and related repository layouts.

---

## Git Conflict Resolution

For a conflicted Git file, AboveDiff reads Git's three conflict stages directly:

```text
Git stage 1 → BASE
Git stage 2 → OURS / LOCAL
Git stage 3 → THEIRS / REMOTE
```

The conflict can then be resolved using AboveDiff's native three-way merge UI.

The resolved file can be written back to the working tree and optionally staged as resolved.

---

## Git Mergetool

AboveDiff can also operate as a native external Git mergetool.

Product name:

```text
AboveDiff
```

CLI / Git tool name:

```text
abovediff
```

Typical Git configuration:

```bash
git config --global merge.tool abovediff

git config --global mergetool.abovediff.cmd \
'abovediff --mergetool --base "$BASE" --local "$LOCAL" --remote "$REMOTE" --merged "$MERGED"'

git config --global mergetool.abovediff.trustExitCode true
```

After configuration:

```bash
git mergetool
```

opens the conflict directly in AboveDiff.

The flow is:

```text
Git
 ↓
abovediff CLI
 ↓
AboveDiff
 ↓
OURS | BASE | THEIRS
 ↓
Resolve conflicts
 ↓
Save & Resolve
 ↓
MERGED file
 ↓
exit 0
 ↓
Git continues
```

---

## Mergetool File Mapping

Git passes four paths to AboveDiff:

```text
$BASE
$LOCAL
$REMOTE
$MERGED
```

AboveDiff interprets them as:

```text
$LOCAL  → OURS
$BASE   → BASE
$REMOTE → THEIRS
$MERGED → final output
```

`Save & Resolve` writes directly to `$MERGED`.

Canceling the merge returns a non-zero exit code so Git keeps the file unresolved.

---

## CLI

The command-line helper is:

```bash
abovediff
```

Check installation:

```bash
command -v abovediff
abovediff --version
```

Typical installation:

```text
/Applications/AboveDiff.app
└── Contents/
    ├── MacOS/
    │   └── AboveDiff
    └── Helpers/
        └── abovediff
```

with:

```text
/usr/local/bin/abovediff
```

linked to:

```text
/Applications/AboveDiff.app/Contents/Helpers/abovediff
```

---

## Mergetool CLI Usage

```bash
abovediff --mergetool \
  --base "$BASE" \
  --local "$LOCAL" \
  --remote "$REMOTE" \
  --merged "$MERGED"
```

Other commands:

```bash
abovediff --help
abovediff --version
```

---

## Architecture

AboveDiff follows a strict dependency direction:

```text
Views
  ↓
State
  ↓
Core
```

Core comparison and merge engines do not depend on SwiftUI or AppKit.

Major components include:

```text
DirectoryCompareEngine
LineDiffEngine
ThreeWayDiffEngine
ThreeWayMergeEngine
GitRepositoryService
GitBlobLoader
GitConflictService
MergeToolSessionStore
```

This separation allows the comparison and merge logic to be tested independently from the macOS interface.

---

## Project Structure

```text
AboveDiff/
├── AboveDiff-macos/
│   ├── Package.swift
│   │
│   ├── Sources/
│   │   ├── App/
│   │   ├── Core/
│   │   │   ├── Diff/
│   │   │   ├── Diff3/
│   │   │   ├── Directory/
│   │   │   ├── Git/
│   │   │   └── Merge/
│   │   │
│   │   ├── Localization/
│   │   ├── State/
│   │   └── Views/
│   │
│   ├── Tests/
│   │   └── AboveDiffTests/
│   │
│   └── CLI/
│       ├── Package.swift
│       └── Sources/
│           └── abovediff/
│
├── assets/
│   └── AboveDiffIcon.png
│
├── docs/
├── scripts/
└── build-macos.sh
```

---

## Build

### GUI application

```bash
cd AboveDiff-macos

swift test
swift build
```

Run:

```bash
swift run AboveDiff
```

Release build:

```bash
swift build -c release
```

---

### CLI

```bash
cd AboveDiff-macos/CLI

swift build
swift run abovediff --version
```

Release build:

```bash
swift build -c release
```

Find the resulting binary:

```bash
swift build -c release --show-bin-path
```

---

## Build the macOS App and DMG

From the repository root:

```bash
chmod +x scripts/build-abovediff-dmg.sh
./scripts/build-abovediff-dmg.sh
```

Expected outputs:

```text
dist/AboveDiff.app
dist/AboveDiff.dmg
```

The release build embeds the `abovediff` CLI inside the application bundle.

---

## Code Signing

For local testing, ad-hoc signing can be used.

For public distribution, use an Apple Developer ID Application certificate:

```bash
export ABOVEDIFF_CODESIGN_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)"
```

Then rebuild:

```bash
./scripts/build-abovediff-dmg.sh
```

---

## Notarization

After configuring `notarytool` credentials:

```bash
./scripts/notarize-abovediff.sh
```

The final DMG should be both signed and notarized before public distribution.

---

## Install Git Mergetool Integration

After copying `AboveDiff.app` to `/Applications`:

```bash
chmod +x scripts/install-abovediff-mergetool.sh
./scripts/install-abovediff-mergetool.sh
```

Check configuration:

```bash
./scripts/check-abovediff-mergetool.sh
```

Repair it if needed:

```bash
./scripts/repair-abovediff-mergetool.sh
```

---

## Git Mergetool Testing

AboveDiff includes reproducible Git conflict tests.

### Single conflict

```bash
./scripts/test-abovediff-mergetool-fixture.sh
```

### Cancel behavior

```bash
./scripts/test-abovediff-mergetool-cancel.sh
```

### Multiple conflicts

```bash
./scripts/test-abovediff-mergetool-multi.sh
```

The tests create temporary Git repositories and do not require modifying a production repository.

---

## macOS

AboveDiff is developed as a native macOS application using:

* Swift
* SwiftUI
* AppKit
* Swift Package Manager

No Python, GTK, GtkSourceView, or Meld runtime installation is required.

---

## Why AboveDiff?

AboveDiff started as a file-management project and evolved into a native comparison and merge environment.

Its goal is to combine:

```text
File management
      +
Folder comparison
      +
2-way diff
      +
3-way diff
      +
3-way merge
      +
Git conflict resolution
      +
git mergetool
```

inside one native macOS application.

---

## Documentation

Additional design and implementation notes are available under:

```text
docs/
```

including the staged diff/merge integration plans, architecture documentation, Git mergetool integration, testing, and release instructions.

---

## Repository

```text
https://github.com/kimdongup/AboveDiff
```

---

## License

See:

```text
LICENSE
```

for the project's licensing terms.
