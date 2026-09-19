# P9 최종 적용 노트

## 추가

Core:
- AboveDiff-macos/Sources/Core/Git/MergeTool/MergeToolSessionMaintenance.swift
- AboveDiff-macos/Sources/Core/Git/MergeTool/GitMergetoolInstallStatus.swift

State:
- AboveDiff-macos/Sources/State/Git/GitIntegrationState.swift

View:
- AboveDiff-macos/Sources/Views/Git/GitIntegrationStatusView.swift

Tests:
- AboveDiff-macos/Tests/AboveDiffTests/MergeToolSessionMaintenanceTests.swift

Scripts:
- scripts/check-abovediff-mergetool.sh
- scripts/repair-abovediff-mergetool.sh

Docs:
- docs/P9_FINALIZATION.md
- docs/P9_RELEASE_CHECKLIST.md

## 교체

- AboveDiff-macos/CLI/Sources/abovediff/main.swift

## 선택적 Preferences 연결

다음을 삽입하세요:

```swift
GitIntegrationStatusView()
```

기존 Preferences Git/Advanced 섹션 안에 넣으세요.

이 뷰는 의도적으로 상태 표시 전용입니다.
설치/복구는 GUI에서 전역 Git 설정을 조용히 변경하지 않도록
P9에서 명시적인 셸 스크립트로 유지합니다.

## 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
swift build -c release

cd CLI
rm -rf .build
swift build -c release
```

그런 다음:

```bash
cd /Users/kimdongup/Bazel/AboveDiff

chmod +x \
  scripts/check-abovediff-mergetool.sh \
  scripts/repair-abovediff-mergetool.sh

./scripts/check-abovediff-mergetool.sh
```
