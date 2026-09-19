# AboveDiff P9 Release Checklist

## Naming
- [ ] Product = AboveDiff
- [ ] CLI = abovediff
- [ ] Git mergetool = abovediff

## Build
- [ ] GUI `swift test`
- [ ] GUI release build
- [ ] CLI release build
- [ ] no debug-only NSLog required for release

## Installation
- [ ] `/Applications/AboveDiff.app`
- [ ] `/usr/local/bin/abovediff`
- [ ] fresh shell finds `abovediff`

## Git config
- [ ] `merge.tool=abovediff`
- [ ] `mergetool.abovediff.cmd`
- [ ] `trustExitCode=true`

## Runtime
- [ ] app closed → `git mergetool` launches app
- [ ] app already running → session opens
- [ ] Save & Resolve → exit 0
- [ ] Cancel → non-zero
- [ ] close window → non-zero
- [ ] timeout does not hang terminal forever
- [ ] stale sessions cleaned

## Paths
- [ ] spaces
- [ ] Unicode/Korean
- [ ] multiple conflict files

## Git fixture
- [ ] single conflict
- [ ] cancel
- [ ] 3 conflicts sequentially
- [ ] `git diff --check`

## Maintenance
- [ ] check script
- [ ] repair script
- [ ] uninstall script
