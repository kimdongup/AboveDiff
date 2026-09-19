# AboveDiff P9 릴리스 체크리스트

## 이름
- [ ] Product = AboveDiff
- [ ] CLI = abovediff
- [ ] Git mergetool = abovediff

## 빌드
- [ ] GUI `swift test`
- [ ] GUI 릴리스 빌드
- [ ] CLI 릴리스 빌드
- [ ] 릴리스에 디버그 전용 NSLog가 필요하지 않음

## 설치
- [ ] `/Applications/AboveDiff.app`
- [ ] `/usr/local/bin/abovediff`
- [ ] 새 셸에서 `abovediff`를 찾음

## Git 설정
- [ ] `merge.tool=abovediff`
- [ ] `mergetool.abovediff.cmd`
- [ ] `trustExitCode=true`

## 런타임
- [ ] 앱이 닫혀 있음 → `git mergetool`이 앱을 실행
- [ ] 앱이 이미 실행 중 → 세션이 열림
- [ ] Save & Resolve → exit 0
- [ ] Cancel → 0이 아님
- [ ] 창 닫기 → 0이 아님
- [ ] 타임아웃이 터미널을 영원히 멈추지 않음
- [ ] 오래된 세션이 정리됨

## 경로
- [ ] 공백
- [ ] 유니코드/한국어
- [ ] 여러 충돌 파일

## Git fixture
- [ ] 단일 충돌
- [ ] 취소
- [ ] 3개 충돌 순차 처리
- [ ] `git diff --check`

## 유지보수
- [ ] check 스크립트
- [ ] repair 스크립트
- [ ] uninstall 스크립트
