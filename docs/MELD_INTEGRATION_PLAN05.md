# MELD_INTEGRATION_PLAN05.md

# AboveDiff P9 — External Git Mergetool Integration

## 0. Final naming

```text
Product / GUI app     AboveDiff
App bundle            AboveDiff.app
GUI executable        AboveDiff
CLI launcher          abovediff
Git mergetool name    abovediff
GitHub repository     kimdongup/AboveDiff
Local repository      /Users/kimdongup/Bazel/AboveDiff
```

Principle:

```text
AboveDiff = product / GUI brand
abovediff = terminal / CLI / Git tool name
```

---

## 1. Does `git config --global merge.tool abovediff` require PATH?

No. This setting alone only tells Git that the selected mergetool is named `abovediff`.

```bash
git config --global merge.tool abovediff
```

The actual executable is determined by:

```bash
git config --global mergetool.abovediff.cmd 'abovediff --mergetool --base "$BASE" --local "$LOCAL" --remote "$REMOTE" --merged "$MERGED"'
```

If the command starts with the bare executable name `abovediff`, then `abovediff` must be discoverable in the shell PATH.

Verify:

```bash
command -v abovediff
```

Recommended result:

```text
/usr/local/bin/abovediff
```

Alternative: use an absolute path in `mergetool.abovediff.cmd`. That avoids PATH, but is less portable if AboveDiff.app is moved.

---

## 2. Recommended installation layout

```text
/Applications/AboveDiff.app
└── Contents/
    ├── MacOS/
    │   └── AboveDiff
    └── Helpers/
        └── abovediff

/usr/local/bin/abovediff
    → /Applications/AboveDiff.app/Contents/Helpers/abovediff
```

Verification:

```bash
ls -l /usr/local/bin/abovediff
command -v abovediff
abovediff --version
```

If `/usr/local/bin` cannot be written without elevated privileges, use:

```text
~/.local/bin/abovediff
```

and ensure:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

is present in `~/.zshrc`.

---

## 3. Target Git configuration

```bash
git config --global merge.tool abovediff

git config --global mergetool.abovediff.cmd 'abovediff --mergetool --base "$BASE" --local "$LOCAL" --remote "$REMOTE" --merged "$MERGED"'

git config --global mergetool.abovediff.trustExitCode true
```

Optional:

```bash
git config --global mergetool.keepBackup false
```

AboveDiff should not silently force the backup policy; expose it as a preference.

Verify:

```bash
git config --global --get merge.tool
git config --global --get mergetool.abovediff.cmd
git config --global --get mergetool.abovediff.trustExitCode
```

---

## 4. Git → AboveDiff contract

Git provides:

```text
$BASE    common ancestor
$LOCAL   ours / local
$REMOTE  theirs / remote
$MERGED  final output file
```

AboveDiff maps them to:

```text
LOCAL  → OURS pane
BASE   → BASE pane
REMOTE → THEIRS pane
MERGED → fixed merge output
```

Flow:

```text
git mergetool
   ↓
abovediff CLI
   ↓
AboveDiff merge session
   ↓
OURS | BASE | THEIRS
   ↓
Resolve conflicts
   ↓
Save & Resolve
   ↓
Write MERGED
   ↓
CLI exit 0
   ↓
Git continues
```

---

## 5. P9.1 — CLI argument model

New files:

```text
Sources/Core/Git/MergeTool/
├── GitMergeToolArguments.swift
└── GitMergeToolExitStatus.swift
```

CLI:

```bash
abovediff --mergetool   --base "/tmp/base"   --local "/tmp/local"   --remote "/tmp/remote"   --merged "/repo/path/file"
```

Also support:

```bash
abovediff --version
abovediff --help
```

Validation:

- BASE / LOCAL / REMOTE / MERGED all present
- input files readable
- MERGED parent writable
- spaces and Unicode paths supported
- binary input rejected by text merge mode

---

## 6. P9.2 — Separate CLI executable target

SwiftPM should expose a separate command-line executable:

```text
target: AboveDiffCLI
executable: abovediff
```

Conceptually:

```swift
.executable(
    name: "abovediff",
    targets: ["AboveDiffCLI"]
)
```

Source:

```text
Sources/CLI/AboveDiffCLI.swift
```

CLI responsibilities:

1. Parse arguments
2. Create merge session request
3. Activate AboveDiff GUI
4. Block until that merge session ends
5. Return the correct process exit code

The CLI does not reimplement diff or merge algorithms.

---

## 7. P9.3 — Merge session model

New Core files:

```text
Sources/Core/Git/MergeTool/
├── MergeToolSession.swift
├── MergeToolSessionRequest.swift
└── MergeToolSessionResult.swift
```

Request:

```text
sessionID
baseURL
localURL
remoteURL
mergedURL
```

Result:

```text
resolved
cancelled
failed
```

---

## 8. P9.4 — ExternalMergeToolState

New:

```text
Sources/State/Git/ExternalMergeToolState.swift
```

Reuse:

```text
ThreeWayDiffEngine
ThreeWayMergeEngine
TextDocumentService
TextFileGuard
```

Difference from normal Three-Way Merge:

```text
Normal mode:
Save Result… → NSSavePanel

Git mergetool mode:
MERGED path is predetermined
Save & Resolve → atomic write directly to MERGED
```

---

## 9. P9.5 — Mergetool-specific UI

New:

```text
Sources/Views/Git/ExternalMergeToolView.swift
```

UI:

```text
┌──────────────────────────────────────────────┐
│ Git Merge — path/to/file.swift               │
├──────────────┬─────────────┬─────────────────┤
│ OURS / LOCAL │ BASE        │ THEIRS / REMOTE │
├──────────────┴─────────────┴─────────────────┤
│ Merge decisions                              │
├──────────────────────────────────────────────┤
│ MERGED RESULT                                │
├──────────────────────────────────────────────┤
│ [Cancel]                    [Save & Resolve] │
└──────────────────────────────────────────────┘
```

`Save & Resolve` is enabled only when:

```text
unresolvedCount == 0
```

---

## 10. P9.6 — Exit-code contract

With:

```bash
git config --global mergetool.abovediff.trustExitCode true
```

use:

```text
0  successful merge + MERGED written
1  user cancelled
2  invalid CLI/configuration
3  load/write error
4  unresolved conflict
5  internal error
```

Only `0` means success.

---

## 11. P9.7 — CLI/GUI communication

Do not make the final implementation depend only on:

```bash
open -W -a AboveDiff
```

because AboveDiff may already be running and Git must wait for one merge session, not for the whole application process.

Recommended first implementation:

```text
~/Library/Caches/AboveDiff/MergeSessions/<UUID>/
├── request.json
└── result.json
```

CLI:

1. Write request.json
2. Activate AboveDiff
3. Wait for result.json
4. Return the session exit code

GUI:

1. Discover pending request
2. Open the corresponding merge window
3. Save & Resolve or Cancel
4. Write result.json

Later this can be upgraded to XPC or a Unix socket.

---

## 12. P9.8 — Git integration installer

Preferences:

```text
Git Integration

[ Install AboveDiff Git Mergetool ]

CLI:
✓ /usr/local/bin/abovediff

Git:
✓ merge.tool = abovediff

☑ Set AboveDiff as default Git mergetool
☑ Trust AboveDiff exit status
```

Installer tasks:

1. Install/symlink CLI launcher
2. Verify `command -v abovediff`
3. Configure `merge.tool`
4. Configure `mergetool.abovediff.cmd`
5. Set `trustExitCode=true`

Removal must restore any pre-existing `merge.tool` value instead of blindly deleting it.

---

## 13. Unit tests

Add:

```text
GitMergeToolArgumentsTests.swift
MergeToolSessionTests.swift
ExternalMergeToolStateTests.swift
GitMergetoolConfigurationTests.swift
```

Cover:

- normal arguments
- missing BASE/LOCAL/REMOTE/MERGED
- paths containing spaces
- Korean/Unicode path
- binary file
- MERGED write failure
- unresolved conflict
- Cancel
- success exit 0

---

## 14. Temp-repository integration test

Create a temporary Git repo.

Base:

```text
value = BASE
```

Branch A:

```text
value = OURS
```

Branch B:

```text
value = THEIRS
```

Create a real merge conflict.

Verify:

```bash
git status --short
```

Expected:

```text
UU test.txt
```

Run:

```bash
git mergetool --tool=abovediff test.txt
```

Resolve in AboveDiff, then:

```bash
git diff --check
git status --short
```

---

## 15. P9.8 real-world `git mergetool` test

Do not test first on `main`.

Create disposable branches:

```text
test/abovediff-base
test/abovediff-local
test/abovediff-remote
```

Modify the same line differently in local and remote branches.

Merge:

```bash
git merge test/abovediff-remote
```

Then:

```bash
git mergetool
```

Expected:

```text
Git
 → abovediff
 → AboveDiff
 → OURS | BASE | THEIRS
 → Save & Resolve
 → MERGED written
 → exit 0
 → Git returns successfully
```

Verify:

```bash
git status
git diff --check
git diff --cc
```

---

## 16. Multi-conflict test

Create conflicts in at least 3 files.

Run:

```bash
git mergetool
```

Verify sequential handling:

```text
file1 → AboveDiff → success
file2 → AboveDiff → success
file3 → AboveDiff → success
```

Important:

- each CLI session blocks correctly
- previous merge window/session cleans up
- AboveDiff app can be reused
- temp session files are removed

---

## 17. Cancel test

Press Cancel in the AboveDiff merge window.

Expected:

```text
CLI exit != 0
```

Verify:

```bash
git status --short
```

The conflict must remain unresolved.

---

## 18. App-running and app-not-running tests

### AboveDiff already running

```bash
git mergetool
```

Expected:

- existing app receives the merge session
- merge window opens
- terminal waits only for the session
- correct exit code returned

### AboveDiff not running

```bash
git mergetool
```

Expected:

- AboveDiff launches automatically
- merge window opens
- terminal resumes after session completion

---

## 19. PATH real-world test

After installation:

```bash
which abovediff
command -v abovediff
zsh -lc 'command -v abovediff'
abovediff --version
```

Recommended:

```text
/usr/local/bin/abovediff
```

This verifies that a fresh login shell can find the launcher, not only the current terminal.

---

## 20. App relocation policy

Recommended supported installation location:

```text
/Applications/AboveDiff.app
```

If the application has moved, the Git integration page should detect the broken launcher and offer:

```text
Repair Git Integration
```

rather than leaving stale Git config silently.

---

## 21. Security

Never concatenate Git-provided paths into a shell command and execute through:

```text
/bin/sh -c
```

Parse and pass paths as arguments/URLs.

Must support paths such as:

```text
/My Repo/한글 파일.swift
```

without manual shell escaping inside the application.

---

## 22. Final file structure

```text
/Users/kimdongup/Bazel/AboveDiff
├── AboveDiff-macos/
│   ├── Sources/
│   │   ├── CLI/
│   │   │   └── AboveDiffCLI.swift
│   │   ├── Core/Git/MergeTool/
│   │   │   ├── GitMergeToolArguments.swift
│   │   │   ├── GitMergeToolExitStatus.swift
│   │   │   ├── MergeToolSession.swift
│   │   │   └── GitMergetoolConfiguration.swift
│   │   ├── State/Git/
│   │   │   └── ExternalMergeToolState.swift
│   │   └── Views/Git/
│   │       └── ExternalMergeToolView.swift
│   └── Tests/AboveDiffTests/
└── MELD_INTEGRATION_PLAN05.md
```

---

## 23. Implementation order

```text
P9.1  GitMergeToolArguments
P9.2  `abovediff` executable target
P9.3  merge session request/result
P9.4  ExternalMergeToolState
P9.5  fixed MERGED output
P9.6  Save & Resolve / Cancel
P9.7  exit-code contract
P9.8  Git config + CLI installer
P9.9  unit tests
P9.10 temp-repository integration test
P9.11 real-world git mergetool test
P9.12 multiple conflict files
P9.13 Cancel behavior
P9.14 app running/not-running behavior
P9.15 install/repair/uninstall polish
```

---

## 24. Definition of Done

- [ ] GUI product is `AboveDiff`
- [ ] terminal command is `abovediff`
- [ ] `command -v abovediff` succeeds
- [ ] `merge.tool = abovediff`
- [ ] `mergetool.abovediff.cmd` configured
- [ ] `trustExitCode = true`
- [ ] BASE/LOCAL/REMOTE/MERGED parsed safely
- [ ] `git mergetool` opens AboveDiff
- [ ] MERGED is the fixed output file
- [ ] Save & Resolve returns exit 0
- [ ] Cancel returns nonzero
- [ ] unresolved conflicts cannot return success
- [ ] spaces/Unicode paths work
- [ ] app-already-running case works
- [ ] multiple conflicts process sequentially
- [ ] real Git repository test passes
- [ ] no Meld/Python/GTK runtime dependency
