# P8 릴리스 체크리스트

## 빌드
- [ ] `swift test`
- [ ] debug 빌드
- [ ] release 빌드
- [ ] 경고 검토 완료

## 아키텍처
- [ ] View가 Git/process 엔진을 직접 실행하지 않음
- [ ] Core가 SwiftUI/AppKit을 import하지 않음
- [ ] 중복 소스 파일 없음
- [ ] 임시 디버그 print 없음

## 비교
- [ ] 폴더 비교
- [ ] 파일 Diff
- [ ] 동기화 스크롤
- [ ] 줄 번호
- [ ] regex 필터
- [ ] 동기화 지점
- [ ] 대용량 파일 경고/가드
- [ ] 바이너리 텍스트 가드

## 3-way
- [ ] 비교
- [ ] 충돌 탐색
- [ ] 병합 결정
- [ ] 병합 결과 저장
- [ ] 소스 pane 동기화

## Git
- [ ] 저장소 탐지
- [ ] HEAD/index/working-tree 비교
- [ ] 충돌 stage 1/2/3 로드
- [ ] working tree에 저장
- [ ] 명시적 Stage as Resolved
- [ ] 저장소 밖에서 Git 메뉴 비활성

## 창 수명 주기
- [ ] 중복 비교 창은 기존 창을 재사용
- [ ] 최소화된 창이 복원됨
- [ ] Dock 활성화 시 비교 창을 앞으로 가져옴
- [ ] 닫으면 registry에서 창 제거

## 릴리스
- [ ] Apple Silicon 빌드
- [ ] 배포 파이프라인이 지원하면 Intel 빌드
- [ ] Python/GTK 런타임 의존성 없음
- [ ] localization 점검
- [ ] accessibility 레이블
- [ ] 키보드 탐색
