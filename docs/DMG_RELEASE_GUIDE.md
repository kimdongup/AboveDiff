# AboveDiff DMG Release Guide

## Final bundle layout

The release app must contain both GUI and CLI:

```text
AboveDiff.app
└── Contents/
    ├── MacOS/
    │   └── AboveDiff
    └── Helpers/
        └── abovediff
```

The Git launcher installed on the user's system is:

```text
/usr/local/bin/abovediff
  → /Applications/AboveDiff.app/Contents/Helpers/abovediff
```

This is important: never symlink `/usr/local/bin/abovediff` to a developer
`.build/.../release/abovediff` path.

## 1. Build and create DMG

```bash
cd /Users/kimdongup/Bazel/AboveDiff

chmod +x \
  scripts/build-abovediff-dmg.sh \
  scripts/install-abovediff-mergetool.sh \
  scripts/notarize-abovediff.sh

./scripts/build-abovediff-dmg.sh
```

Expected output:

```text
dist/AboveDiff.app
dist/AboveDiff.dmg
```

## 2. Developer ID signing

For public distribution, set:

```bash
export ABOVEDIFF_CODESIGN_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)"
```

Then rebuild:

```bash
./scripts/build-abovediff-dmg.sh
```

The default identity is `-`, which is only ad-hoc signing and is suitable for
local testing, not normal public macOS distribution.

## 3. Notarization

Store credentials once:

```bash
xcrun notarytool store-credentials "AboveDiffNotary" \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

Then:

```bash
export ABOVEDIFF_NOTARY_PROFILE="AboveDiffNotary"

./scripts/notarize-abovediff.sh
```

## 4. Clean-machine installation test

On another Mac or a clean user account:

1. Mount `AboveDiff.dmg`.
2. Drag `AboveDiff.app` to `/Applications`.
3. Launch AboveDiff.
4. Confirm:

```bash
/Applications/AboveDiff.app/Contents/Helpers/abovediff --version
```

5. Install Git integration using the installer script supplied separately, or
   copy/run the installer from the release support package.

6. Verify:

```bash
command -v abovediff
abovediff --version

git config --global --get merge.tool
git config --global --get mergetool.abovediff.cmd
git config --global --get mergetool.abovediff.trustExitCode
```

## 5. Real mergetool regression

Run the existing fixture tests:

```bash
./scripts/test-abovediff-mergetool-fixture.sh
./scripts/test-abovediff-mergetool-cancel.sh
./scripts/test-abovediff-mergetool-multi.sh
```

## 6. Final checks

```bash
codesign --verify --deep --strict --verbose=2 \
  /Applications/AboveDiff.app

spctl --assess --type execute --verbose \
  /Applications/AboveDiff.app

hdiutil verify dist/AboveDiff.dmg
```
