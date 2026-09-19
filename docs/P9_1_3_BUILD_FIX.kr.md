# P9.1-P9.3 빌드 수정

## 원인

첫 번째 P9 패치는 `AboveDiffCLI`를 메인 GUI 패키지의 두 번째 실행 파일 타깃으로
추가했습니다. 현재 Xcode/SwiftPM explicit-module 빌드에서는
`abovediff` 빌드가 GUI 실행 파일 타깃을 동시에 의존성 스캔하게 만들고,
그 스캔이 `AboveDiffState` / `AboveDiffViews`를 해석하는 동안 실패했습니다.

CLI는 해당 모듈이 필요하지 않으므로, 깔끔한 해결책은 CLI를
별도의 중첩 Swift 패키지로 분리하는 것입니다.

## 1. 복원

다음을 교체하세요:

```text
AboveDiff-macos/Package.swift
```

제공된 파일로 교체하세요. 현재 GitHub main 버전과 동일한 패키지 그래프이며
CLI 타깃은 포함하지 않습니다.

## 2. 기존 CLI 파일 삭제

다음을 삭제하세요:

```text
AboveDiff-macos/Sources/CLI/AboveDiffCLI.swift
```

`Sources/CLI`가 비게 되면 해당 디렉터리도 제거하세요.

## 3. 별도 CLI 패키지 추가

다음을 추가하세요:

```text
AboveDiff-macos/CLI/Package.swift
AboveDiff-macos/CLI/Sources/abovediff/main.swift
```

CLI 패키지는 부모 패키지의 `AboveDiffCore` 프로덕트에만 의존합니다.

## 4. P9 Core 파일 유지

삭제하지 마세요:

```text
AboveDiff-macos/Sources/Core/Git/MergeTool/GitMergeToolArguments.swift
AboveDiff-macos/Sources/Core/Git/MergeTool/GitMergeToolExitStatus.swift
AboveDiff-macos/Sources/Core/Git/MergeTool/MergeToolSession.swift
```

해당 테스트도 유지하세요.

## 5. GUI 패키지 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos

rm -rf .build
swift test
swift build
```

## 6. CLI를 별도로 검증

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos/CLI

rm -rf .build
swift build

swift run abovediff --help
swift run abovediff --version
```

예상 결과:

```text
abovediff 1.0.0
```

## 7. CLI 바이너리 찾기

```bash
swift build -c release --show-bin-path
```

해당 디렉터리의 `abovediff` 바이너리가 P9.8에서 `/usr/local/bin/abovediff`로
패키징하거나 심링크할 실행 파일입니다.
