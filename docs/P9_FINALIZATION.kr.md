# P9 최종화

아래 항목이 모두 통과하면 AboveDiff 외부 Git mergetool 연동이 완료된 것입니다.

## 런타임 아키텍처

```text
git mergetool
  ↓
/usr/local/bin/abovediff
  ↓
request.json
  ↓
/Applications/AboveDiff.app
  ↓
MergeToolSessionCoordinator
  ↓
ExternalMergeToolView
  ↓
Save & Resolve / Cancel
  ↓
result.json
  ↓
CLI exit status
  ↓
Git continues or stops
```

## 제품 / CLI 이름

```text
Product      AboveDiff
CLI          abovediff
Git tool     abovediff
```

## 프로덕션 경로

```text
/Applications/AboveDiff.app
/usr/local/bin/abovediff
~/Library/Caches/AboveDiff/MergeSessions
```

## 상태 점검

```bash
cd /Users/kimdongup/Bazel/AboveDiff

chmod +x \
  scripts/check-abovediff-mergetool.sh \
  scripts/repair-abovediff-mergetool.sh

./scripts/check-abovediff-mergetool.sh
```

## 복구

```bash
./scripts/repair-abovediff-mergetool.sh
```

## 타임아웃

기본 외부 병합 세션 타임아웃:

```text
1800 seconds (30 minutes)
```

디버깅용 재정의:

```bash
ABOVEDIFF_SESSION_TIMEOUT=60 git mergetool
```

## 오래된 세션

CLI는 새 세션을 만들기 전에 24시간이 지난 세션을 제거합니다.

## 회귀 테스트

실행:

```bash
./scripts/test-abovediff-mergetool-fixture.sh
./scripts/test-abovediff-mergetool-cancel.sh
./scripts/test-abovediff-mergetool-multi.sh
```

## 릴리스 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
swift test
swift build -c release

cd CLI
swift build -c release
```

그런 다음:

```bash
command -v abovediff
abovediff --version
git mergetool --tool=abovediff
```
