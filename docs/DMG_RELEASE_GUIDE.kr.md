# AboveDiff DMG 릴리스 가이드

## 최종 번들 레이아웃

릴리스 앱에는 GUI와 CLI가 모두 포함되어야 합니다:

```text
AboveDiff.app
└── Contents/
    ├── MacOS/
    │   └── AboveDiff
    └── Helpers/
        └── abovediff
```

사용자 시스템에 설치되는 Git 런처는 다음과 같습니다:

```text
/usr/local/bin/abovediff
  → /Applications/AboveDiff.app/Contents/Helpers/abovediff
```

중요: `/usr/local/bin/abovediff`를 개발자
`.build/.../release/abovediff` 경로에 심볼릭 링크로 연결하지 마세요.

## 1. 빌드 및 DMG 생성

```bash
cd /Users/kimdongup/Bazel/AboveDiff

chmod +x \
  scripts/build-abovediff-dmg.sh \
  scripts/install-abovediff-mergetool.sh \
  scripts/notarize-abovediff.sh

./scripts/build-abovediff-dmg.sh
```

예상 출력:

```text
dist/AboveDiff.app
dist/AboveDiff.dmg
```

## 2. Developer ID 서명

공개 배포의 경우, 다음을 설정하세요:

```bash
export ABOVEDIFF_CODESIGN_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)"
```

그런 다음 다시 빌드하세요:

```bash
./scripts/build-abovediff-dmg.sh
```

기본 identity는 `-`이며, 이는 ad-hoc 서명일 뿐이고
로컬 테스트에만 적합하며 일반적인 공개 macOS 배포에는 적합하지 않습니다.

## 3. 공증 (Notarization)

자격 증명을 한 번 저장하세요:

```bash
xcrun notarytool store-credentials "AboveDiffNotary" \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

그런 다음:

```bash
export ABOVEDIFF_NOTARY_PROFILE="AboveDiffNotary"

./scripts/notarize-abovediff.sh
```

## 4. 클린 머신 설치 테스트

다른 Mac 또는 깨끗한 사용자 계정에서:

1. `AboveDiff.dmg`를 마운트합니다.
2. `AboveDiff.app`을 `/Applications`로 드래그합니다.
3. AboveDiff를 실행합니다.
4. 다음을 확인합니다:

```bash
/Applications/AboveDiff.app/Contents/Helpers/abovediff --version
```

5. 별도로 제공된 설치 스크립트를 사용하여 Git 연동을 설치하거나,
   릴리스 지원 패키지에서 설치 프로그램을 복사/실행합니다.

6. 다음을 확인합니다:

```bash
command -v abovediff
abovediff --version

git config --global --get merge.tool
git config --global --get mergetool.abovediff.cmd
git config --global --get mergetool.abovediff.trustExitCode
```

## 5. 실제 mergetool 회귀 테스트

기존 fixture 테스트를 실행합니다:

```bash
./scripts/test-abovediff-mergetool-fixture.sh
./scripts/test-abovediff-mergetool-cancel.sh
./scripts/test-abovediff-mergetool-multi.sh
```

## 6. 최종 점검

```bash
codesign --verify --deep --strict --verbose=2 \
  /Applications/AboveDiff.app

spctl --assess --type execute --verbose \
  /Applications/AboveDiff.app

hdiutil verify dist/AboveDiff.dmg
```
