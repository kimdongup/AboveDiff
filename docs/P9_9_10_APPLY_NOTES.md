# P9.9-P9.10 Apply Notes

Add:

```text
scripts/test-abovediff-mergetool-fixture.sh
scripts/test-abovediff-mergetool-cancel.sh
scripts/test-abovediff-mergetool-multi.sh
docs/P9_9_10_TEST_MATRIX.md
```

Make executable:

```bash
cd /Users/kimdongup/Bazel/AboveDiff

chmod +x \
  scripts/test-abovediff-mergetool-fixture.sh \
  scripts/test-abovediff-mergetool-cancel.sh \
  scripts/test-abovediff-mergetool-multi.sh
```

Run in this order:

```bash
./scripts/test-abovediff-mergetool-fixture.sh
./scripts/test-abovediff-mergetool-cancel.sh
./scripts/test-abovediff-mergetool-multi.sh
```

Do not use a production repository for the first test.
