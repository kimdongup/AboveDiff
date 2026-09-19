# P9.9-P9.10 테스트 매트릭스

## 전제 조건

```bash
command -v abovediff
abovediff --version

git config --global --get merge.tool
git config --global --get mergetool.abovediff.cmd
git config --global --get mergetool.abovediff.trustExitCode
```

예상 결과:

```text
/usr/local/bin/abovediff
abovediff 1.0.0
abovediff
... --mergetool ...
true
```

## 테스트 A — 성공적인 단일 충돌

```bash
cd /Users/kimdongup/Bazel/AboveDiff
chmod +x scripts/test-abovediff-mergetool-fixture.sh
./scripts/test-abovediff-mergetool-fixture.sh
```

예상 결과:
- AboveDiff가 자동으로 열림
- 병합 세션 하나
- Save & Resolve
- CLI exit 0
- `git diff --check` 통과

## 테스트 B — 취소

```bash
chmod +x scripts/test-abovediff-mergetool-cancel.sh
./scripts/test-abovediff-mergetool-cancel.sh
```

예상 결과:
- Cancel 클릭
- CLI가 0이 아닌 값을 반환
- `UU test.txt`가 그대로 남음

## 테스트 C — 다중 충돌

```bash
chmod +x scripts/test-abovediff-mergetool-multi.sh
./scripts/test-abovediff-mergetool-multi.sh
```

예상 결과:
- 3개의 AboveDiff 세션이 순차적으로 처리됨
- `UU` 항목이 남아 있지 않음
- `git diff --check` 통과

## 테스트 D — 공백 / 유니코드가 있는 경로

다음을 사용:

```bash
export ABOVEDIFF_FIXTURE_ROOT="/tmp/AboveDiff 한글 Test"
./scripts/test-abovediff-mergetool-fixture.sh
```

예상 결과:
- 세션이 정상적으로 열림
- 인용된 경로가 보존됨
- 성공적으로 exit 0

## 테스트 E — AboveDiff가 이미 실행 중

시작:

```bash
open -a /Applications/AboveDiff.app
```

그런 다음 fixture 테스트를 실행합니다.

예상 결과:
- 기존 앱이 요청을 수신
- 의도하지 않은 추가 앱 프로세스가 필요하지 않음
- 병합 창이 열림

## 테스트 F — AboveDiff가 실행 중이 아님

```bash
killall AboveDiff 2>/dev/null || true
./scripts/test-abovediff-mergetool-fixture.sh
```

예상 결과:
- 앱이 자동으로 실행됨
- 병합 창이 열림
- 터미널이 세션 완료를 기다림
