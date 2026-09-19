# MELD_INTEGRATION_PLAN05.md

# AboveDiff P9 — 외부 Git Mergetool 연동

## 0. 최종 명칭

```text
제품 / GUI 앱          AboveDiff
앱 번들                AboveDiff.app
GUI 실행 파일          AboveDiff
CLI 런처               abovediff
Git mergetool 이름     abovediff
GitHub 저장소          kimdongup/AboveDiff
로컬 저장소            /Users/kimdongup/Bazel/AboveDiff
```

원칙:

```text
AboveDiff = 제품 / GUI 브랜드
abovediff = 터미널 / CLI / Git 도구 이름
```

---

## 1. `git config --global merge.tool abovediff`는 PATH가 필요한가?

아니요. 이 설정만으로는 Git에게 선택한 mergetool의 이름이 `abovediff`라는 것만 알려 줍니다.

```bash
git config --global merge.tool abovediff
```

실제 실행 파일은 다음으로 결정됩니다:

```bash
git config --global mergetool.abovediff.cmd 'abovediff --mergetool --base "$BASE" --local "$LOCAL" --remote "$REMOTE" --merged "$MERGED"'
```

명령이 실행 파일 이름 `abovediff`만으로 시작하면, 셸 PATH에서 `abovediff`를 찾을 수 있어야 합니다.

확인:

```bash
command -v abovediff
```

권장 결과:

```text
/usr/local/bin/abovediff
```

대안: `mergetool.abovediff.cmd`에 절대 경로를 사용합니다. 이렇게 하면 PATH가 필요 없지만, AboveDiff.app을 옮기면 이식성이 떨어집니다.

---

## 2. 권장 설치 레이아웃

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

확인:

```bash
ls -l /usr/local/bin/abovediff
command -v abovediff
abovediff --version
```

`/usr/local/bin`에 권한 상승 없이 쓸 수 없으면 다음을 사용합니다:

```text
~/.local/bin/abovediff
```

그리고 다음이:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

`~/.zshrc`에 들어 있어야 합니다.

---

## 3. 목표 Git 설정

```bash
git config --global merge.tool abovediff

git config --global mergetool.abovediff.cmd 'abovediff --mergetool --base "$BASE" --local "$LOCAL" --remote "$REMOTE" --merged "$MERGED"'

git config --global mergetool.abovediff.trustExitCode true
```

선택 사항:

```bash
git config --global mergetool.keepBackup false
```

AboveDiff는 백업 정책을 조용히 강제하지 말고, 환경설정으로 노출해야 합니다.

확인:

```bash
git config --global --get merge.tool
git config --global --get mergetool.abovediff.cmd
git config --global --get mergetool.abovediff.trustExitCode
```

---

## 4. Git → AboveDiff 계약

Git이 제공하는 값:

```text
$BASE    공통 조상
$LOCAL   ours / 로컬
$REMOTE  theirs / 원격
$MERGED  최종 출력 파일
```

AboveDiff는 이를 다음과 같이 매핑합니다:

```text
LOCAL  → OURS 페인
BASE   → BASE 페인
REMOTE → THEIRS 페인
MERGED → 고정 병합 출력
```

흐름:

```text
git mergetool
   ↓
abovediff CLI
   ↓
AboveDiff 병합 세션
   ↓
OURS | BASE | THEIRS
   ↓
충돌 해결
   ↓
Save & Resolve
   ↓
MERGED 기록
   ↓
CLI exit 0
   ↓
Git 계속 진행
```

---

## 5. P9.1 — CLI 인자 모델

새 파일:

```text
Sources/Core/Git/MergeTool/
├── GitMergeToolArguments.swift
└── GitMergeToolExitStatus.swift
```

CLI:

```bash
abovediff --mergetool   --base "/tmp/base"   --local "/tmp/local"   --remote "/tmp/remote"   --merged "/repo/path/file"
```

다음도 지원:

```bash
abovediff --version
abovediff --help
```

검증:

- BASE / LOCAL / REMOTE / MERGED가 모두 존재
- 입력 파일을 읽을 수 있음
- MERGED 부모 디렉터리에 쓸 수 있음
- 공백과 Unicode 경로 지원
- 텍스트 병합 모드에서 바이너리 입력은 거부

---

## 6. P9.2 — 별도 CLI 실행 파일 타깃

SwiftPM은 별도의 커맨드라인 실행 파일을 노출해야 합니다:

```text
target: AboveDiffCLI
executable: abovediff
```

개념적으로:

```swift
.executable(
    name: "abovediff",
    targets: ["AboveDiffCLI"]
)
```

소스:

```text
Sources/CLI/AboveDiffCLI.swift
```

CLI 책임:

1. 인자 파싱
2. 병합 세션 요청 생성
3. AboveDiff GUI 활성화
4. 해당 병합 세션이 끝날 때까지 대기
5. 올바른 프로세스 종료 코드 반환

CLI는 diff나 merge 알고리즘을 다시 구현하지 않습니다.

---

## 7. P9.3 — 병합 세션 모델

새 Core 파일:

```text
Sources/Core/Git/MergeTool/
├── MergeToolSession.swift
├── MergeToolSessionRequest.swift
└── MergeToolSessionResult.swift
```

요청:

```text
sessionID
baseURL
localURL
remoteURL
mergedURL
```

결과:

```text
resolved
cancelled
failed
```

---

## 8. P9.4 — ExternalMergeToolState

새로 추가:

```text
Sources/State/Git/ExternalMergeToolState.swift
```

재사용:

```text
ThreeWayDiffEngine
ThreeWayMergeEngine
TextDocumentService
TextFileGuard
```

일반 Three-Way Merge와의 차이:

```text
일반 모드:
Save Result… → NSSavePanel

Git mergetool 모드:
MERGED 경로가 미리 정해져 있음
Save & Resolve → MERGED에 직접 원자적 기록
```

---

## 9. P9.5 — Mergetool 전용 UI

새로 추가:

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
│ 병합 결정                                    │
├──────────────────────────────────────────────┤
│ MERGED RESULT                                │
├──────────────────────────────────────────────┤
│ [Cancel]                    [Save & Resolve] │
└──────────────────────────────────────────────┘
```

`Save & Resolve`는 다음일 때만 활성화됩니다:

```text
unresolvedCount == 0
```

---

## 10. P9.6 — 종료 코드 계약

다음 설정과 함께:

```bash
git config --global mergetool.abovediff.trustExitCode true
```

다음을 사용합니다:

```text
0  병합 성공 + MERGED 기록
1  사용자 취소
2  잘못된 CLI/설정
3  로드/쓰기 오류
4  미해결 충돌
5  내부 오류
```

`0`만 성공을 의미합니다.

---

## 11. P9.7 — CLI/GUI 통신

최종 구현이 다음에만 의존하게 하지 마십시오:

```bash
open -W -a AboveDiff
```

AboveDiff가 이미 실행 중일 수 있고, Git은 애플리케이션 프로세스 전체가 아니라 하나의 병합 세션이 끝날 때까지 기다려야 하기 때문입니다.

권장 1차 구현:

```text
~/Library/Caches/AboveDiff/MergeSessions/<UUID>/
├── request.json
└── result.json
```

CLI:

1. request.json 기록
2. AboveDiff 활성화
3. result.json 대기
4. 세션 종료 코드 반환

GUI:

1. 대기 중인 요청 발견
2. 해당 병합 창 열기
3. Save & Resolve 또는 Cancel
4. result.json 기록

이후 XPC 또는 Unix 소켓으로 업그레이드할 수 있습니다.

---

## 12. P9.8 — Git 연동 설치기

환경설정:

```text
Git 연동

[ AboveDiff Git Mergetool 설치 ]

CLI:
✓ /usr/local/bin/abovediff

Git:
✓ merge.tool = abovediff

☑ AboveDiff를 기본 Git mergetool로 설정
☑ AboveDiff 종료 상태를 신뢰
```

설치기 작업:

1. CLI 런처 설치/심볼릭 링크
2. `command -v abovediff` 확인
3. `merge.tool` 설정
4. `mergetool.abovediff.cmd` 설정
5. `trustExitCode=true` 설정

제거 시에는 기존 `merge.tool` 값을 무조건 지우지 말고, 원래 값으로 복원해야 합니다.

---

## 13. 단위 테스트

추가:

```text
GitMergeToolArgumentsTests.swift
MergeToolSessionTests.swift
ExternalMergeToolStateTests.swift
GitMergetoolConfigurationTests.swift
```

다룰 내용:

- 정상 인자
- BASE/LOCAL/REMOTE/MERGED 누락
- 공백이 포함된 경로
- 한글/Unicode 경로
- 바이너리 파일
- MERGED 쓰기 실패
- 미해결 충돌
- Cancel
- 성공 종료 코드 0

---

## 14. 임시 저장소 통합 테스트

임시 Git 저장소를 만듭니다.

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

실제 병합 충돌을 만듭니다.

확인:

```bash
git status --short
```

기대 결과:

```text
UU test.txt
```

실행:

```bash
git mergetool --tool=abovediff test.txt
```

AboveDiff에서 해결한 다음:

```bash
git diff --check
git status --short
```

---

## 15. P9.8 실제 `git mergetool` 테스트

먼저 `main`에서 테스트하지 마십시오.

일회용 브랜치를 만듭니다:

```text
test/abovediff-base
test/abovediff-local
test/abovediff-remote
```

로컬과 원격 브랜치에서 같은 줄을 서로 다르게 수정합니다.

병합:

```bash
git merge test/abovediff-remote
```

그다음:

```bash
git mergetool
```

기대 결과:

```text
Git
 → abovediff
 → AboveDiff
 → OURS | BASE | THEIRS
 → Save & Resolve
 → MERGED 기록
 → exit 0
 → Git이 성공적으로 복귀
```

확인:

```bash
git status
git diff --check
git diff --cc
```

---

## 16. 다중 충돌 테스트

최소 3개 파일에 충돌을 만듭니다.

실행:

```bash
git mergetool
```

순차 처리를 확인합니다:

```text
file1 → AboveDiff → 성공
file2 → AboveDiff → 성공
file3 → AboveDiff → 성공
```

중요:

- 각 CLI 세션이 올바르게 대기(block)할 것
- 이전 병합 창/세션이 정리될 것
- AboveDiff 앱을 재사용할 수 있을 것
- 임시 세션 파일이 제거될 것

---

## 17. Cancel 테스트

AboveDiff 병합 창에서 Cancel을 누릅니다.

기대 결과:

```text
CLI exit != 0
```

확인:

```bash
git status --short
```

충돌은 미해결 상태로 남아 있어야 합니다.

---

## 18. 앱 실행 중 / 미실행 테스트

### AboveDiff가 이미 실행 중

```bash
git mergetool
```

기대 결과:

- 기존 앱이 병합 세션을 받음
- 병합 창이 열림
- 터미널은 세션만 기다림
- 올바른 종료 코드가 반환됨

### AboveDiff가 실행 중이 아님

```bash
git mergetool
```

기대 결과:

- AboveDiff가 자동으로 실행됨
- 병합 창이 열림
- 세션이 끝나면 터미널이 재개됨

---

## 19. PATH 실제 환경 테스트

설치 후:

```bash
which abovediff
command -v abovediff
zsh -lc 'command -v abovediff'
abovediff --version
```

권장:

```text
/usr/local/bin/abovediff
```

이는 현재 터미널뿐 아니라, 새로 로그인한 셸에서도 런처를 찾을 수 있는지 확인합니다.

---

## 20. 앱 위치 이동 정책

권장 지원 설치 위치:

```text
/Applications/AboveDiff.app
```

애플리케이션이 옮겨졌다면, Git 연동 페이지가 깨진 런처를 감지하고 다음을 제안해야 합니다:

```text
Git 연동 복구
```

오래된 Git 설정을 조용히 남겨 두지 마십시오.

---

## 21. 보안

Git이 제공한 경로를 셸 명령에 이어 붙여 다음으로 실행하지 마십시오:

```text
/bin/sh -c
```

경로를 인자/URL로 파싱하여 전달하십시오.

다음과 같은 경로를 지원해야 합니다:

```text
/My Repo/한글 파일.swift
```

애플리케이션 내부에서 수동 셸 이스케이프 없이 처리해야 합니다.

---

## 22. 최종 파일 구조

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

## 23. 구현 순서

```text
P9.1  GitMergeToolArguments
P9.2  `abovediff` 실행 파일 타깃
P9.3  병합 세션 request/result
P9.4  ExternalMergeToolState
P9.5  고정 MERGED 출력
P9.6  Save & Resolve / Cancel
P9.7  종료 코드 계약
P9.8  Git config + CLI 설치기
P9.9  단위 테스트
P9.10 임시 저장소 통합 테스트
P9.11 실제 git mergetool 테스트
P9.12 다중 충돌 파일
P9.13 Cancel 동작
P9.14 앱 실행 중/미실행 동작
P9.15 설치/복구/제거 다듬기
```

---

## 24. 완료 기준

- [ ] GUI 제품은 `AboveDiff`
- [ ] 터미널 명령은 `abovediff`
- [ ] `command -v abovediff`가 성공함
- [ ] `merge.tool = abovediff`
- [ ] `mergetool.abovediff.cmd`가 설정됨
- [ ] `trustExitCode = true`
- [ ] BASE/LOCAL/REMOTE/MERGED를 안전하게 파싱함
- [ ] `git mergetool`이 AboveDiff를 연다
- [ ] MERGED가 고정 출력 파일임
- [ ] Save & Resolve는 exit 0을 반환함
- [ ] Cancel은 0이 아닌 값을 반환함
- [ ] 미해결 충돌은 성공을 반환할 수 없음
- [ ] 공백/Unicode 경로가 동작함
- [ ] 앱이 이미 실행 중인 경우가 동작함
- [ ] 여러 충돌을 순차로 처리함
- [ ] 실제 Git 저장소 테스트가 통과함
- [ ] Meld/Python/GTK 런타임 의존성 없음
