# P6 menu integration

## New files

```text
Sources/Views/Compare/ThreeWayFilePicker.swift
Sources/Views/Compare/ThreeWayCompareLauncher.swift
```

## Manual edit

`Sources/App/AboveDiffApp.swift` 또는 현재 app entry 파일의 Tools menu에
`ABOVEDIFFAPP_MENU_PATCH.md` 내용을 추가합니다.

## Test

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
swift run
```

## Expected flow

Tools > Three-Way Compare…
1. Select LOCAL
2. Select BASE
3. Select REMOTE
4. 3-pane compare window opens

Tools > Three-Way Merge…
1. Select LOCAL
2. Select BASE
3. Select REMOTE
4. merge resolver opens
