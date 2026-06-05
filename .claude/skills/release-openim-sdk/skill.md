---
name: release-openim-sdk
description: |
  Full release automation for OpenIM SDK React Native wrapper. Use this skill whenever the user wants to release, build, or publish the OpenIM SDK — whether they say "release openim", "build sdk", "tạo release", "chạy release sdk", "publish sdk reactnative", or any variation. Also trigger when the user mentions building AAR/xcframework and pushing to the RN project.

  This skill handles the complete pipeline: pulling a source tag from openimsdk-core → building Android AAR and iOS xcframework via gomobile → copying artifacts into open-im-sdk-reactnative → patching native imports to use local files → versioning and git tagging.
---

# Release OpenIM SDK

This skill automates the full release pipeline for the OpenIM SDK React Native wrapper. It takes a source tag from `openimsdk-core`, builds Android and iOS native libraries, integrates them into `open-im-sdk-reactnative`, and publishes a new versioned release.

## Paths

Derive paths dynamically — the skill is always invoked from within the `open-im-sdk-reactnative` repo, and both repos are siblings in the same parent directory:

```bash
RN_DIR=$(git rev-parse --show-toplevel)
CORE_DIR=$(dirname "$RN_DIR")/openimsdk-core
```

Use `$RN_DIR` and `$CORE_DIR` everywhere instead of hardcoded paths.

---

## Step 1 — Get source tag

Ask the user:

> Nhập tag của openimsdk-core cần build (VD: v3.8.3-patch.11):

Store the answer as `SOURCE_TAG`.

---

## Step 2 — Pull tag from openimsdk-core

```bash
RN_DIR=$(git rev-parse --show-toplevel)
CORE_DIR=$(dirname "$RN_DIR")/openimsdk-core
cd "$CORE_DIR"
git fetch --tags
git checkout <SOURCE_TAG>
```

Confirm the checkout succeeded before proceeding.

---

## Step 3 — Build Android AAR

```bash
RN_DIR=$(git rev-parse --show-toplevel)
CORE_DIR=$(dirname "$RN_DIR")/openimsdk-core
cd "$CORE_DIR"
make android
```

Expected output: `open_im_sdk.aar` in the project root directory. This may take several minutes — inform the user that the build is in progress.

---

## Step 4 — Build iOS xcframework

```bash
RN_DIR=$(git rev-parse --show-toplevel)
CORE_DIR=$(dirname "$RN_DIR")/openimsdk-core
cd "$CORE_DIR"
make ios
```

Expected output: `build/OpenIMCore.xcframework` in the project root. Also takes several minutes.

---

## Step 5 — Prepare artifact directories

```bash
RN_DIR=$(git rev-parse --show-toplevel)
mkdir -p "$RN_DIR/native-libs/android"
mkdir -p "$RN_DIR/native-libs/ios"
```

---

## Step 6 — Copy artifacts (always replace existing)

Remove any previously built files first to ensure a clean copy:

```bash
RN_DIR=$(git rev-parse --show-toplevel)
CORE_DIR=$(dirname "$RN_DIR")/openimsdk-core

rm -f "$RN_DIR/native-libs/android/open_im_sdk.aar"
rm -rf "$RN_DIR/native-libs/ios/OpenIMCore.xcframework"

cp "$CORE_DIR/open_im_sdk.aar" "$RN_DIR/native-libs/android/open_im_sdk.aar"
cp -r "$CORE_DIR/build/OpenIMCore.xcframework" "$RN_DIR/native-libs/ios/OpenIMCore.xcframework"
```

Verify both files exist after copying before continuing.

---

## Step 7 — Patch Android: switch from Maven remote to local AAR

File: `android/build.gradle` inside the RN project.

Find and replace the remote dependency with the local fileTree import:

**Before:**
```gradle
implementation("com.droppii:core-sdk:+")
```

**After:**
```gradle
implementation fileTree(dir: '../native-libs/android', include: ['*.aar'])
```

Use the Edit tool to make this change precisely — do not alter any other lines.

---

## Step 8 — Patch iOS podspec: switch from CocoaPods to local xcframework

File: `open-im-sdk-rn.podspec` inside the RN project.

Read the file and find the line that matches `s.dependency "DroppiiOpenIMSDKCore"` (any version string). Use the exact text found as `old_string` in the Edit tool, and replace the entire line with:

```ruby
s.vendored_frameworks = 'native-libs/ios/OpenIMCore.xcframework'
```

Use the Edit tool — one precise replacement, nothing else changed.

---

## Step 9 — Get release version and update package.json

Ask the user:

> Nhập version release cho open-im-sdk-reactnative (VD: 1.0.0-rc4):

Store the answer as `RELEASE_VERSION`.

Update the `version` field in `package.json` to `RELEASE_VERSION` using the Edit tool.

---

## Step 10 — Commit, tag, and push

```bash
RN_DIR=$(git rev-parse --show-toplevel)
cd "$RN_DIR"
git add android/build.gradle open-im-sdk-rn.podspec package.json native-libs/
git commit -m "chore: release <RELEASE_VERSION> - use local OpenIM SDK built from <SOURCE_TAG>"
git tag "v<RELEASE_VERSION>"
git push origin HEAD
git push origin "v<RELEASE_VERSION>"
```

Substitute `<RELEASE_VERSION>` and `<SOURCE_TAG>` with the actual values collected earlier.

After pushing, inform the user that the `v<RELEASE_VERSION>` tag has been pushed and the GitHub Actions `release.yml` workflow will automatically trigger to publish the npm package.

---

## Error handling

- If `make android` or `make ios` fails, stop and show the error output to the user. Do not proceed to copy or patch files.
- If either artifact file is missing after the build, report the missing file and stop.
- If a git command fails (e.g., tag already exists), report the exact error and ask the user how to proceed.
