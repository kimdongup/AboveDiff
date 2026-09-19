# AboveDiff DMG 릴리스 적용 노트

## 추가

```text
scripts/build-abovediff-dmg.sh
scripts/notarize-abovediff.sh
docs/DMG_RELEASE_GUIDE.md
```

## 교체

```text
scripts/install-abovediff-mergetool.sh
```

설치 프로그램은 이제 다음을 연결합니다:

```text
/usr/local/bin/abovediff
→ /Applications/AboveDiff.app/Contents/Helpers/abovediff
```

개발자 SwiftPM `.build` 디렉터리 대신입니다.

## 빌드

```bash
cd /Users/kimdongup/Bazel/AboveDiff

chmod +x \
  scripts/build-abovediff-dmg.sh \
  scripts/install-abovediff-mergetool.sh \
  scripts/notarize-abovediff.sh

./scripts/build-abovediff-dmg.sh
```

예상 결과:

```text
dist/AboveDiff.app
dist/AboveDiff.dmg
```

## 중요

이 스크립트는 기존 루트 `build-macos.sh`가 다음을 생성한다고 가정합니다:

```text
dist/AboveDiff.app
```

현재 빌드 스크립트가 다른 경로를 출력한다면, 다음만 변경하세요:

```bash
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
```

`scripts/build-abovediff-dmg.sh`에서.

공개 배포의 경우, ad-hoc 서명 (`-`)을 Developer ID
Application 인증서로 바꾸고 DMG를 공증(notarize)하세요.
