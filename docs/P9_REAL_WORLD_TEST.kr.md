# P9.8 — 실제 `git mergetool` 테스트

## 1. AboveDiff.app 빌드/패키징

최신 앱이 다음 위치에 있는지 확인하세요:

```text
/Users/kimdongup/Bazel/AboveDiff/dist/AboveDiff.app
```

## 2. 설치

저장소 루트에서:

```bash
cd /Users/kimdongup/Bazel/AboveDiff

chmod +x scripts/install-abovediff-mergetool.sh
./scripts/install-abovediff-mergetool.sh
```

확인:

```bash
command -v abovediff
abovediff --version

git config --global --get merge.tool
git config --global --get mergetool.abovediff.cmd
git config --global --get mergetool.abovediff.trustExitCode
```

예상 결과:

```text
/usr/local/bin/abovediff
abovediff 1.0.0
abovediff
abovediff --mergetool ...
true
```

## 3. 일회용 fixture 저장소 생성

```bash
rm -rf /tmp/abovediff-git-fixture
mkdir -p /tmp/abovediff-git-fixture
cd /tmp/abovediff-git-fixture

git init
git config user.name "AboveDiff Test"
git config user.email "abovediff@example.test"

printf 'line1\nvalue = BASE\nline3\n' > test.txt

git add test.txt
git commit -m "base"

git switch -c local
printf 'line1\nvalue = LOCAL\nline3\n' > test.txt
git commit -am "local change"

git switch -c remote HEAD~1
printf 'line1\nvalue = REMOTE\nline3\n' > test.txt
git commit -am "remote change"

git switch local
git merge remote
```

충돌이 예상됩니다.

확인:

```bash
git status --short
```

예상 결과:

```text
UU test.txt
```

## 4. AboveDiff 실행

```bash
git mergetool --tool=abovediff test.txt
```

예상 결과:
1. `/Applications/AboveDiff.app`이 활성화됩니다.
2. `AboveDiff Git Mergetool` 창이 열립니다.
3. OURS / BASE / THEIRS가 표시됩니다.
4. 충돌을 해결합니다.
5. `Save & Resolve`를 클릭합니다.
6. 터미널이 성공적으로 반환됩니다.

확인:

```bash
echo $?
cat test.txt
git status --short
git diff --check
```

종료 코드는 `0`이어야 합니다.

Git mergetool 동작에 따라, Git은 도구가 성공적으로 종료되고 변경된 MERGED 파일을
기준으로 파일이 해결된 것으로 간주할 수 있습니다. 아직 unstaged 상태라면
다음을 실행하세요:

```bash
git add test.txt
```

원하면 P9.9에서 명시적 staging 동작을 선택적으로 통합할 수 있습니다.

## 5. 취소 테스트

충돌을 다시 만들고 다음을 실행하세요:

```bash
git mergetool --tool=abovediff test.txt
```

Cancel을 클릭하거나 병합 창을 닫습니다.

예상 결과:

```bash
echo $?
```

0이 아닌 값, 보통 `1`.

충돌은 미해결 상태로 남아 있어야 합니다.

## 6. 여러 파일

충돌이 있는 파일 3개를 만들고 다음을 실행하세요:

```bash
git mergetool --tool=abovediff
```

Git이 한 번에 하나의 AboveDiff 세션을 실행하고, 각 세션에서
성공적인 `Save & Resolve` 뒤에 다음으로 진행하는지 확인하세요.
