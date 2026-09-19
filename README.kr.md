<h1>
  <img src="assets/AboveDiffIcon.png" width="72" alt="AboveDiff 아이콘" align="absmiddle">
  AboveDiff
</h1>

**macOS용 네이티브 diff, 비교, 병합, Git 충돌 해결.**

AboveDiff는 빠른 **2-way diff**, **3-way diff**, **폴더 비교**, **병합 충돌 해결**, **Git mergetool 연동**을 위해 만든 네이티브 macOS 파일 관리자이자 비교 도구입니다.

파일과 디렉터리를 비교하고, 충돌하는 버전을 해결하며, 변경을 병합하는 시각적 워크플로를 제공합니다. Python, GTK, Meld 또는 다른 외부 GUI 런타임은 필요하지 않습니다.

---

## 기능

### 파일 Diff

두 텍스트 파일을 나란히 비교합니다.

* 줄 단위 diff
* 삽입 / 삭제 / 교체 강조
* 동기화 스크롤
* 줄 번호
* 이전 / 다음 변경 이동
* 개요 맵
* 왼쪽·오른쪽 페인 편집
* 변경 블록을 파일 간에 개별 복사
* 왼쪽 / 오른쪽 / 모두 저장
* 네이티브 macOS 실행 취소 / 다시 실행
* 대용량 파일 보호

---

### 3-way Diff

다음을 비교합니다:

```text
LOCAL  |  BASE  |  REMOTE
```

AboveDiff는 변경을 다음과 같이 분류합니다:

```text
equal
localOnly
remoteOnly
sameChange
conflict
```

공통 베이스에서 두 버전이 어떻게 갈라졌는지 이해하기 쉽습니다.

포함 기능:

* 동기화된 3개 페인
* 충돌만 이동
* 줄 번호
* 변경 개요
* 충돌 강조
* LOCAL / BASE / REMOTE 시각화

---

### 3-way Merge

다음으로 충돌을 대화형으로 해결합니다:

```text
Use Local
Use Remote
Use Base
Local → Remote
Remote → Local
```

병합 결과는 저장 전에 계속 편집할 수 있습니다.

충돌이 아닌 변경은 자동 병합할 수 있고, 미해결 충돌은 따로 추적됩니다.

---

### 폴더 비교

두 디렉터리를 재귀적으로 비교합니다.

비교 모드:

```text
Smart
Metadata
Content
```

기능:

* Same / Modified / Left Only / Right Only / Error 필터
* 재귀 비교
* 숨김 파일 옵션
* 파일 이름 포함 / 제외 필터
* Glob 또는 정규식 매칭
* 왼쪽 → 오른쪽 복사
* 오른쪽 → 왼쪽 복사
* 수정된 파일을 File Diff에서 바로 열기
* 오래 걸리는 비교 취소

---

### Diff 필터

AboveDiff는 비교별 필터링을 지원합니다.

#### 빈 줄 무시

표시되는 파일을 수정하지 않고 비교에서 빈 줄을 제외할 수 있습니다.

#### 정규식 필터

타임스탬프, 생성된 ID, 버전 문자열 같은 차이를 비교 중에 정규화할 수 있습니다.

예:

```text
Left:
timestamp=123456

Right:
timestamp=987654
```

정규식:

```regex
timestamp=\d+
```

치환:

```text
timestamp=<ignored>
```

원문 텍스트는 그대로 보이고, 정규화된 값은 diff 엔진에서 동일한 것으로 취급됩니다.

---

### 동기화 지점

자동 정렬이 모호한 어려운 파일에는 수동 동기화 지점을 지정할 수 있습니다.

예:

```text
Left line 22 ↔ Right line 26
```

이 줄들을 정렬 앵커로 쓰라고 AboveDiff에 알려 줍니다.

동기화 지점 줄 번호는 일반적인 **1부터 시작하는 번호**로 표시됩니다.

---

## Git 연동

AboveDiff는 Git working-tree, staged, HEAD, 충돌 상태를 이해합니다.

지원하는 비교:

```text
Working Tree ↔ HEAD
Staged       ↔ HEAD
Working Tree ↔ Staged
```

Git 저장소는 `.git` 디렉터리 존재 여부만 보지 않고 다음으로 탐지합니다:

```bash
git rev-parse --show-toplevel
```

Git worktree와 관련 저장소 레이아웃도 지원합니다.

---

## Git 충돌 해결

충돌이 난 Git 파일에 대해 AboveDiff는 Git의 세 충돌 스테이지를 직접 읽습니다:

```text
Git stage 1 → BASE
Git stage 2 → OURS / LOCAL
Git stage 3 → THEIRS / REMOTE
```

이후 AboveDiff의 네이티브 3-way merge UI로 충돌을 해결할 수 있습니다.

해결된 파일은 working tree에 다시 쓰고, 선택적으로 resolved로 스테이징할 수 있습니다.

---

## Git Mergetool

AboveDiff는 네이티브 외부 Git mergetool로도 동작합니다.

제품 이름:

```text
AboveDiff
```

CLI / Git 도구 이름:

```text
abovediff
```

일반적인 Git 설정:

```bash
git config --global merge.tool abovediff

git config --global mergetool.abovediff.cmd \
'abovediff --mergetool --base "$BASE" --local "$LOCAL" --remote "$REMOTE" --merged "$MERGED"'

git config --global mergetool.abovediff.trustExitCode true
```

설정 후:

```bash
git mergetool
```

을 실행하면 충돌이 AboveDiff에서 바로 열립니다.

흐름은 다음과 같습니다:

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

## Mergetool 파일 매핑

Git은 AboveDiff에 네 개의 경로를 넘깁니다:

```text
$BASE
$LOCAL
$REMOTE
$MERGED
```

AboveDiff는 이를 다음과 같이 해석합니다:

```text
$LOCAL  → OURS
$BASE   → BASE
$REMOTE → THEIRS
$MERGED → final output
```

`Save & Resolve`는 `$MERGED`에 직접 씁니다.

병합을 취소하면 0이 아닌 종료 코드를 반환해 Git이 파일을 미해결 상태로 유지합니다.

---

## CLI

명령줄 헬퍼는 다음과 같습니다:

```bash
abovediff
```

설치 확인:

```bash
command -v abovediff
abovediff --version
```

일반적인 설치:

```text
/Applications/AboveDiff.app
└── Contents/
    ├── MacOS/
    │   └── AboveDiff
    └── Helpers/
        └── abovediff
```

그리고:

```text
/usr/local/bin/abovediff
```

가 다음을 가리킵니다:

```text
/Applications/AboveDiff.app/Contents/Helpers/abovediff
```

---

## Mergetool CLI 사용법

```bash
abovediff --mergetool \
  --base "$BASE" \
  --local "$LOCAL" \
  --remote "$REMOTE" \
  --merged "$MERGED"
```

기타 명령:

```bash
abovediff --help
abovediff --version
```

---

## 아키텍처

AboveDiff는 의존 방향을 엄격히 지킵니다:

```text
Views
  ↓
State
  ↓
Core
```

Core의 비교·병합 엔진은 SwiftUI나 AppKit에 의존하지 않습니다.

주요 구성 요소:

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

이 분리 덕분에 비교·병합 로직을 macOS 인터페이스와 독립적으로 테스트할 수 있습니다.

---

## 프로젝트 구조

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

## 빌드

### GUI 애플리케이션

```bash
cd AboveDiff-macos

swift test
swift build
```

실행:

```bash
swift run AboveDiff
```

릴리스 빌드:

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

릴리스 빌드:

```bash
swift build -c release
```

생성된 바이너리 위치 확인:

```bash
swift build -c release --show-bin-path
```

---

## macOS 앱과 DMG 빌드

저장소 루트에서:

```bash
chmod +x scripts/build-abovediff-dmg.sh
./scripts/build-abovediff-dmg.sh
```

예상 출력:

```text
dist/AboveDiff.app
dist/AboveDiff.dmg
```

릴리스 빌드는 `abovediff` CLI를 애플리케이션 번들 안에 넣습니다.

---

## 코드 서명

로컬 테스트에는 ad-hoc 서명을 사용할 수 있습니다.

공개 배포에는 Apple Developer ID Application 인증서를 사용하세요:

```bash
export ABOVEDIFF_CODESIGN_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)"
```

그런 다음 다시 빌드합니다:

```bash
./scripts/build-abovediff-dmg.sh
```

---

## 공증(Notarization)

`notarytool` 자격 증명을 설정한 뒤:

```bash
./scripts/notarize-abovediff.sh
```

공개 배포 전 최종 DMG는 서명과 공증이 모두 되어 있어야 합니다.

---

## Git Mergetool 연동 설치

`AboveDiff.app`을 `/Applications`에 복사한 뒤:

```bash
chmod +x scripts/install-abovediff-mergetool.sh
./scripts/install-abovediff-mergetool.sh
```

설정 확인:

```bash
./scripts/check-abovediff-mergetool.sh
```

필요하면 복구:

```bash
./scripts/repair-abovediff-mergetool.sh
```

---

## Git Mergetool 테스트

AboveDiff에는 재현 가능한 Git 충돌 테스트가 포함되어 있습니다.

### 단일 충돌

```bash
./scripts/test-abovediff-mergetool-fixture.sh
```

### 취소 동작

```bash
./scripts/test-abovediff-mergetool-cancel.sh
```

### 여러 충돌

```bash
./scripts/test-abovediff-mergetool-multi.sh
```

테스트는 임시 Git 저장소를 만들며, 운영 저장소를 수정할 필요가 없습니다.

---

## macOS

AboveDiff는 다음을 사용하는 네이티브 macOS 애플리케이션으로 개발됩니다:

* Swift
* SwiftUI
* AppKit
* Swift Package Manager

Python, GTK, GtkSourceView, Meld 런타임 설치는 필요하지 않습니다.

---

## 왜 AboveDiff인가?

AboveDiff는 파일 관리 프로젝트로 시작해 네이티브 비교·병합 환경으로 발전했습니다.

목표는 다음을 하나의 네이티브 macOS 앱에 모으는 것입니다:

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

---

## 문서

추가 설계·구현 노트는 다음에 있습니다:

```text
docs/
```

단계별 diff/merge 통합 계획, 아키텍처 문서, Git mergetool 연동, 테스트, 릴리스 안내가 포함됩니다.

---

## 저장소

```text
https://github.com/kimdongup/AboveDiff
```

---

## 라이선스

프로젝트 라이선스 조건은 다음을 참고하세요:

```text
LICENSE
```
