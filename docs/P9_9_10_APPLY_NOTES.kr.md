# P9.9-P9.10 적용 노트

추가:

```text
scripts/test-abovediff-mergetool-fixture.sh
scripts/test-abovediff-mergetool-cancel.sh
scripts/test-abovediff-mergetool-multi.sh
docs/P9_9_10_TEST_MATRIX.md
```

실행 권한 부여:

```bash
cd /Users/kimdongup/Bazel/AboveDiff

chmod +x \
  scripts/test-abovediff-mergetool-fixture.sh \
  scripts/test-abovediff-mergetool-cancel.sh \
  scripts/test-abovediff-mergetool-multi.sh
```

이 순서로 실행:

```bash
./scripts/test-abovediff-mergetool-fixture.sh
./scripts/test-abovediff-mergetool-cancel.sh
./scripts/test-abovediff-mergetool-multi.sh
```

첫 테스트에는 프로덕션 저장소를 사용하지 마세요.
