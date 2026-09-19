# P9.8 — Real `git mergetool` test

## 1. Build/package AboveDiff.app

Ensure the latest app exists at:

```text
/Users/kimdongup/Bazel/AboveDiff/dist/AboveDiff.app
```

## 2. Install

From repository root:

```bash
cd /Users/kimdongup/Bazel/AboveDiff

chmod +x scripts/install-abovediff-mergetool.sh
./scripts/install-abovediff-mergetool.sh
```

Verify:

```bash
command -v abovediff
abovediff --version

git config --global --get merge.tool
git config --global --get mergetool.abovediff.cmd
git config --global --get mergetool.abovediff.trustExitCode
```

Expected:

```text
/usr/local/bin/abovediff
abovediff 1.0.0
abovediff
abovediff --mergetool ...
true
```

## 3. Create disposable fixture repository

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

A conflict is expected.

Check:

```bash
git status --short
```

Expected:

```text
UU test.txt
```

## 4. Run AboveDiff

```bash
git mergetool --tool=abovediff test.txt
```

Expected:
1. `/Applications/AboveDiff.app` activates.
2. `AboveDiff Git Mergetool` window opens.
3. OURS / BASE / THEIRS are shown.
4. Resolve the conflict.
5. Click `Save & Resolve`.
6. terminal returns successfully.

Check:

```bash
echo $?
cat test.txt
git status --short
git diff --check
```

The exit code should be `0`.

Depending on Git mergetool behavior, Git may consider the file resolved based
on the successful tool exit and changed MERGED file. If it remains unstaged,
run:

```bash
git add test.txt
```

P9.9 may optionally integrate explicit staging behavior if desired.

## 5. Cancel test

Re-create the conflict, run:

```bash
git mergetool --tool=abovediff test.txt
```

Click Cancel or close the merge window.

Expected:

```bash
echo $?
```

non-zero, normally `1`.

The conflict must remain unresolved.

## 6. Multiple files

Create 3 conflicted files and run:

```bash
git mergetool --tool=abovediff
```

Verify Git launches one AboveDiff session at a time and proceeds after each
successful `Save & Resolve`.
