# AboveDiff 비교 / 병합 사용자 가이드

## 폴더 비교
Smart, Metadata, 또는 Content 모드로 왼쪽/오른쪽 폴더를 비교합니다.
파일 이름에 include/exclude 필터를 사용합니다.

## 파일 Diff
두 파일을 열어 다음을 할 수 있습니다:
- 강조된 변경 사항 보기
- 어느 쪽이든 편집
- 현재 변경을 왼쪽/오른쪽으로 복사
- 어느 쪽이든 저장
- regex 필터 사용
- 빈 줄 무시
- 동기화 지점 정의
- 스크롤 동기화
- 줄 번호 보기

## 3-way 비교
다음을 선택합니다:
1. LOCAL
2. BASE
3. REMOTE

Previous/Next 및 Conflicts Only를 사용합니다.

## 3-way 병합
다음으로 충돌을 해결합니다:
- Use Local
- Use Remote
- Use Base
- Local → Remote
- Remote → Local

병합 결과는 계속 편집할 수 있습니다.

## Git 비교
사용 가능한 비교:
- Working Tree vs HEAD
- Staged vs HEAD
- Working Tree vs Staged

## Git 충돌 해결
충돌이 있는 파일에 대해:
1. Resolve Git Conflict를 엽니다.
2. AboveDiff가 OURS / BASE / THEIRS를 불러옵니다.
3. 모든 충돌을 해결합니다.
4. Working Tree에 저장합니다.
5. 선택적으로 Stage as Resolved를 선택합니다.

Stage as Resolved는 사용자가 명시적으로 동작한 후에만 `git add`를 실행합니다.

## Git mergetool

mergetool 이름은 `abovediff`입니다.

```bash
git config --global merge.tool abovediff
git config --global mergetool.abovediff.trustExitCode true
```

향후 CLI:

```bash
abovediff --mergetool \
  --base "$BASE" \
  --local "$LOCAL" \
  --remote "$REMOTE" \
  --merged "$MERGED"
```
