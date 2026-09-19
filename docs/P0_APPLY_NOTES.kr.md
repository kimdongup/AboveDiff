# P0 적용 노트

이 번들의 내용을 경로를 유지한 채로 저장소 루트에 복사하세요.

그런 다음 실행하세요:

```bash
cd AboveDiff-macos
swift test
```

중요:
- `Sources/Core/Compare`, `Sources/Core/Directory`, `Sources/Core/Diff`,
  그리고 `Sources/State/Compare`는 새 디렉터리입니다.
- `Sources/Core/DirectorySyncEngine.swift`는 교체용 호환성 파사드입니다.
- `Sources/Views/Tools/DirectorySyncSheet.swift`는 View가 더 이상
  Core 엔진을 직접 호출하지 않도록 교체됩니다.
- `Package.swift`는 각 모듈 타깃이 이미
  상위 소스 디렉터리를 재귀적으로 가리키므로 변경이 필요하지 않습니다.
