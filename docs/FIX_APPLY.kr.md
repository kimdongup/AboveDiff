# P0 Fix 1

이 패치는 첫 번째 P0 병합 이후 빌드 로그 오류를 수정합니다.

## 핵심 원인

저장소가 여전히 이전 `Sources/Core/DirectorySyncEngine.swift`를 컴파일하고 있었으며,
이 파일은 다음만 노출했습니다:

```swift
compareDirectories(... compareChecksum: Bool ...)
```

하지만 `DirectoryCompareState.swift`는 새 오버로드를 호출합니다:

```swift
compareDirectories(... comparisonMode: FileComparisonMode ...)
```

따라서 `DirectorySyncEngine.swift`는 줄 단위로 병합하지 말고 REPLACED해야 합니다.

## 교체할 파일

다음 세 파일을 완전히 교체하세요:

1. `AboveDiff-macos/Sources/Core/DirectorySyncEngine.swift`
2. `AboveDiff-macos/Sources/Core/Directory/DirectorySyncExecutor.swift`
3. `AboveDiff-macos/Sources/Core/Directory/DirectorySyncPlanner.swift`

그런 다음 클린하고 테스트하세요:

```bash
cd /Users/kimdongup/Bazel/AboveDiff/AboveDiff-macos
rm -rf .build
swift test
```

빌드 전 선택적 확인:

```bash
grep -n "comparisonMode" Sources/Core/DirectorySyncEngine.swift
```

새 오버로드가 나타나야 합니다.
