# FX File Compare / Merge User Guide

## Folder Compare
Compare left/right folders using Smart, Metadata, or Content mode.
Use include/exclude filters for file names.

## File Diff
Open two files to:
- view highlighted changes
- edit either side
- copy a current change left/right
- save either side
- use regex filters
- ignore blank lines
- define sync points
- synchronize scrolling
- view line numbers

## Three-Way Compare
Select:
1. LOCAL
2. BASE
3. REMOTE

Use Previous/Next and Conflicts Only.

## Three-Way Merge
Resolve conflicts with:
- Use Local
- Use Remote
- Use Base
- Local → Remote
- Remote → Local

The merged result remains editable.

## Git Compare
Available comparisons:
- Working Tree vs HEAD
- Staged vs HEAD
- Working Tree vs Staged

## Resolve Git Conflict
For a conflicted file:
1. Open Resolve Git Conflict.
2. FX File loads OURS / BASE / THEIRS.
3. Resolve all conflicts.
4. Save to Working Tree.
5. Optionally choose Stage as Resolved.

Stage as Resolved runs `git add` only after explicit user action.
