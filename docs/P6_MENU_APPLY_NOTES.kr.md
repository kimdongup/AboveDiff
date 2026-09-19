# P6 메뉴 통합

## 새 파일

```text
Sources/Views/Compare/ThreeWayFilePicker.swift
Sources/Views/Compare/ThreeWayCompareLauncher.swift
```

## 수동 편집

`Sources/App/AboveDiffApp.swift` 또는 현재 앱 진입점 파일의 Tools 메뉴에
`ABOVEDIFFAPP_MENU_PATCH.md` 내용을 추가합니다.

## 테스트

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
swift run
```

## 예상 흐름

Tools > Three-Way Compare…
1. LOCAL 선택
2. BASE 선택
3. REMOTE 선택
4. 3-pane 비교 창이 열립니다

Tools > Three-Way Merge…
1. LOCAL 선택
2. BASE 선택
3. REMOTE 선택
4. 병합 해결기가 열립니다
