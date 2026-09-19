# AboveDiff DMG Release Apply Notes

## Add

```text
scripts/build-abovediff-dmg.sh
scripts/notarize-abovediff.sh
docs/DMG_RELEASE_GUIDE.md
```

## Replace

```text
scripts/install-abovediff-mergetool.sh
```

The installer now links:

```text
/usr/local/bin/abovediff
→ /Applications/AboveDiff.app/Contents/Helpers/abovediff
```

instead of a developer SwiftPM `.build` directory.

## Build

```bash
cd /Users/kimdongup/Bazel/AboveDiff

chmod +x \
  scripts/build-abovediff-dmg.sh \
  scripts/install-abovediff-mergetool.sh \
  scripts/notarize-abovediff.sh

./scripts/build-abovediff-dmg.sh
```

Expected:

```text
dist/AboveDiff.app
dist/AboveDiff.dmg
```

## Important

The script assumes the existing root `build-macos.sh` produces:

```text
dist/AboveDiff.app
```

If your current build script outputs a different path, change only:

```bash
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
```

in `scripts/build-abovediff-dmg.sh`.

For public distribution, replace ad-hoc signing (`-`) with a Developer ID
Application certificate and notarize the DMG.
