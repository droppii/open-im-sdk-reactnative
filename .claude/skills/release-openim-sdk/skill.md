---
name: release-openim-sdk
description: |
  Full release automation for OpenIM SDK React Native wrapper. Use this skill whenever the user wants to release, build, or publish the OpenIM SDK — whether they say "release openim", "build sdk", "tạo release", "chạy release sdk", "publish sdk reactnative", or any variation. Also trigger when the user mentions building AAR/xcframework and pushing to the RN project.

  This skill handles the complete pipeline: pulling a source tag from openimsdk-core → building Android AAR and iOS xcframework via gomobile → copying artifacts into open-im-sdk-reactnative → diffing Go source to detect ALL changes → updating Android, iOS, and TypeScript bridges.
---

# Release OpenIM SDK

This skill automates the full release pipeline for the OpenIM SDK React Native wrapper. It takes a source tag from `openimsdk-core`, builds Android and iOS native libraries, integrates them into `open-im-sdk-reactnative`, and automatically updates all bridge layers with every change detected in the new SDK version.

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

> Nhập tag của openimsdk-core cần build (VD: 0.0.1-rc11):

Store the answer as `SOURCE_TAG`.

Pull latest main branch of `open-im-sdk-reactnative` trước để đảm bảo `.last-core-tag` và các bridge files là mới nhất:

```bash
cd "$RN_DIR"
git pull origin main
```

Sau đó fetch tags từ `openimsdk-core` và đọc last built tag:

```bash
cd "$CORE_DIR"
git fetch --tags

LAST_TAG_FILE="$RN_DIR/.last-core-tag"
if [ -f "$LAST_TAG_FILE" ]; then
  PREV_TAG=$(cat "$LAST_TAG_FILE")
else
  PREV_TAG=""
fi
```

Inform the user: "Sẽ diff từ `$PREV_TAG` → `$SOURCE_TAG`" (nếu có). If `PREV_TAG` is empty (file chưa tồn tại = lần build đầu tiên), do a full analysis of all Go source files instead of a diff.

---

## Step 2 — Pull tag from openimsdk-core

```bash
cd "$CORE_DIR"
git checkout <SOURCE_TAG>
```

Confirm the checkout succeeded before proceeding.

---

## Step 3 — Build Android AAR

```bash
cd "$CORE_DIR"
make android
```

Expected output: `open_im_sdk.aar` in the project root directory. This may take several minutes — inform the user that the build is in progress.

---

## Step 4 — Build iOS xcframework

```bash
cd "$CORE_DIR"
make ios
```

Expected output: `build/OpenIMCore.xcframework` in the project root. Also takes several minutes.

---

## Step 5 — Prepare artifact directories

```bash
mkdir -p "$RN_DIR/native-libs/android"
mkdir -p "$RN_DIR/native-libs/ios"
```

---

## Step 6 — Copy artifacts (always replace existing)

```bash
rm -f "$RN_DIR/native-libs/android/open_im_sdk.aar"
rm -rf "$RN_DIR/native-libs/ios/OpenIMCore.xcframework"

cp "$CORE_DIR/open_im_sdk.aar" "$RN_DIR/native-libs/android/open_im_sdk.aar"
cp -r "$CORE_DIR/build/OpenIMCore.xcframework" "$RN_DIR/native-libs/ios/OpenIMCore.xcframework"
```

Verify both files exist after copying before continuing.

Then save the current tag so the next build knows where to diff from:

```bash
echo "$SOURCE_TAG" > "$RN_DIR/.last-core-tag"
```

Add `.last-core-tag` to `.gitignore` if it isn't already tracked (check with `git ls-files .last-core-tag`). If not tracked, append it:

```bash
grep -qxF '.last-core-tag' "$RN_DIR/.gitignore" || echo '.last-core-tag' >> "$RN_DIR/.gitignore"
```

---

## Step 7 — Diff Go source to detect all changes

This is the primary source of truth. The Go source captures **everything**: new functions, new callbacks, new struct fields, renamed fields, new types, new enums — things that header/javap analysis would miss.

### Diff toàn bộ Go source

Diff **toàn bộ** repo Go (trừ test và vendor) để không bao giờ miss khi core SDK thêm logic ở file mới:

```bash
cd "$CORE_DIR"
git diff "$PREV_TAG" "$SOURCE_TAG" -- '*.go' \
  | grep -v "^diff.*_test\.go\|^diff.*vendor/\|^diff.*wasm/"
```

Đọc toàn bộ output. Bỏ qua các thay đổi trong `internal/` trừ khi chúng ảnh hưởng đến public API (function exported trong `open_im_sdk/`, interface trong `open_im_sdk_callback/`, struct trong `sdk_struct/` hoặc `pkg/`).

### What to look for in the diff

**A) New exported functions** — new `func Xxx(...)` in `open_im_sdk/*.go`
- These need new bridge methods in Android (`@ReactMethod`) and iOS (`RCT_EXPORT_METHOD`)
- And new TypeScript declarations in `OpenIMSDK.native.ts` + `sdk.ts`

**B) New callback methods** — new method added to an interface in `open_im_sdk_callback/callback_client.go`
- Example: `OnRecvMessagePinned(message string)` added to `OnAdvancedMsgListener`
- These need: Android `AdvancedMsgListener.java` override, iOS `supportedEvents` + handler, TS event constant + type

**C) New struct fields** — new `FieldName type` line inside a `type Xxx struct` block in ANY of these files:
- `sdk_struct/sdk_struct.go`
- `pkg/sdk_params_callback/*.go`
- `pkg/db/model_struct/data_model_struct.go` — internal DB model, nhưng các struct như `LocalUser`, `LocalConversation`, `LocalBlack`… được JSON-serialize và trả về qua callback → phải sync với TS types

These need the corresponding TypeScript type in `src/types/entity.ts` or `src/types/params.ts` to be updated.

**D) New struct types** — new `type Xxx struct` added
- Need new TypeScript type definition in `src/types/entity.ts`

**E) Changed/removed items** — `-` lines showing removals or renames
- Flag these to the user as potentially breaking changes

**F) New message type constants** — new `Xxx = NNN` in any `constant.go` file, **any numeric contentType constant, not limited to a fixed range** — this includes actual message content types (e.g. `StickerMessage = 162`, `MarkdownText = 118`, `ReactionMessageModifier = 121`) AND notification content types (e.g. `GroupCreatedNotification = 1501`, `FriendDeletedNotification = 1205`) — `MessageType` in `src/types/enum.ts` already spans both:
- `pkg/constant/constant.go` — upstream SDK constants
- `protocol/constant/constant.go` — Droppii-specific constants
- New values in either file need a new entry in `MessageType` enum in `src/types/enum.ts`

**Do not gate this on a numeric range heuristic** — a fixed "100–200" window under-covers `MessageType` (which already holds values up to 2200+) and has historically let real additions (`MarkdownText`, `ReactionMessageModifier`, several `*Notification` constants) go unnoticed for multiple releases, since diff-based detection only catches what changed between the two tags being compared and never re-checks anything from before tracking started. Run the full-audit check below every release, not just when the diff happens to show something in-range.

### Full audit — run this every release, independent of the diff

The diff in this step only shows what changed **between `$PREV_TAG` and `$SOURCE_TAG`**. It cannot catch a constant that was added before `.last-core-tag` tracking began, or missed by a prior release. Close that gap with a direct set-difference between every numeric constant in the Go source and every value already in `MessageType`:

```bash
comm -23 \
  <(grep -hoE '=[[:space:]]*[0-9]+' \
      "$CORE_DIR/pkg/constant/constant.go" "$CORE_DIR/protocol/constant/constant.go" \
    | grep -oE '[0-9]+' | sort -u) \
  <(grep -oE '=[[:space:]]*[0-9]+' "$RN_DIR/src/types/enum.ts" | grep -oE '[0-9]+' | sort -u) \
  | sort -n
```

**Important:** sort each side with plain `sort -u` (lexicographic), never `sort -un` (numeric) — `comm` compares lines byte-for-byte and requires both inputs in the same collation order; numeric sort ("2" before "10") diverges from lexicographic order ("10" before "2") and silently desyncs `comm`, producing false "missing" hits for values that already exist on both sides. Only pipe the final result through `sort -n` for human-readable output.

This lists every numeric constant value that exists in the Go source but has no matching value anywhere in `enum.ts`. Expect noise — protocol opcodes (`GetNewestSeq`, `PushMsg`, `MsgSyncBegin`, and similar `ReqIdentifier`-style constants), internal `Cmd2Value`/`Action` codes (e.g. `ConChange = 6`), size/limit constants (e.g. `MaxSyncPullNumber = 500`), section range markers (`*NotificationBegin`/`*NotificationEnd`), and even commented-out constants (the grep does not strip `//` comments) all share the same numeric space but are not message content types. For each remaining candidate, look up its name in the Go source and judge whether it is genuinely a `MsgData.ContentType`/notification content type (same judgment already applied to the diff output above) before adding it to `MessageType`.

---

## Step 8 — Read current bridge files

Read these files to know what is currently implemented before making any edits:

- `android/src/main/java/com/openimsdkrn/OpenImSdkRnModule.java`
- `android/src/main/java/com/openimsdkrn/listener/AdvancedMsgListener.java`
- `ios/OpenImSdkRn.m`
- `src/OpenIMSDK.native.ts`
- `src/sdk.ts`
- `src/constants/OpenIMEvents.ts`
- `src/types/eventArgs.ts`
- `src/types/entity.ts`
- `src/types/params.ts`

---

## Step 9 — Apply all updates

For each change detected in Step 7, apply edits using the Edit tool.

### Go type → TypeScript type mapping

Use this table when a Go struct name must be mapped to its TypeScript equivalent:

| Go struct | TypeScript type | File |
|---|---|---|
| `MsgStruct` | `MessageItem` | `entity.ts` |
| `MessagePinned` | `MessagePinned` | `entity.ts` |
| `MessageRevoked` | `MessageRevoked` | `entity.ts` |
| `MessageReceipt` | `MessageReceipt` | `entity.ts` |
| `ConversationStruct` (from server proto) | `ConversationItem` | `entity.ts` |
| `PublicUser` | `PublicUserItem` | `entity.ts` |
| `FriendInfo` (from server proto) | `FriendItem` | `entity.ts` |
| `GroupInfo` (from server proto) | `GroupItem` | `entity.ts` |
| `GroupMemberInfo` | `GroupMemberItem` | `entity.ts` |
| `PinnedMsgInfo` | `PinnedMsgInfo` | `entity.ts` |
| `GetAdvancedHistoryMessageListCallback` | `AdvancedGetMessageResult` | `entity.ts` |
| `GetPinnedMessageListCallback` | `GetPinnedMessageListResult` | `entity.ts` |
| `GetPinnedMessageListParams` | `GetPinnedMessageListParams` | `params.ts` |
| `SearchLocalMessagesParams` | `SearchLocalParams` | `params.ts` |
| `FindMessageListCallback` | `FindMessageResult` | `entity.ts` |

If a Go struct is NOT in this table, use the Go name as the TypeScript name (PascalCase) and add it to `entity.ts`. Also add a comment `// TODO: verify mapping from Go struct <GoName>` if uncertain.

### Go field type → TypeScript type mapping

| Go type | TypeScript type |
|---|---|
| `string` | `string` |
| `int`, `int32`, `int64` | `number` |
| `bool` | `boolean` |
| `[]string` | `string[]` |
| `[]*MsgStruct` | `MessageItem[]` |
| any pointer to a known struct | the mapped TS type |
| `interface{}` | `unknown` |

### Applying changes

**A) New exported function → bridge method:**

Android `OpenImSdkRnModule.java`:
```java
@ReactMethod
public void methodName(String param1, String operationID, Promise promise) {
  Open_im_sdk.methodName(param1, new BaseCallback(promise), operationID);
}
```
For object params: accept `ReadableMap options` and use `map2string(options)` to serialize.

iOS `OpenImSdkRn.m`:
```objc
RCT_EXPORT_METHOD(methodName:(NSString *)param1 operationID:(NSString *)operationID resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  Open_im_sdkMethodName(param1, [BaseCallback new:operationID resolve:resolve reject:reject], operationID);
}
```
For object params: accept `NSDictionary *options` and serialize:
```objc
NSData *data = [NSJSONSerialization dataWithJSONObject:options options:0 error:nil];
NSString *optStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
```

TypeScript `OpenIMSDK.native.ts` — add to interface:
```ts
methodName: (param1: string, operationID: string) => Promise<ReturnType>;
```

TypeScript `sdk.ts` — add wrapper:
```ts
methodName(param1: string, operationID: string = id()) {
  return this._module.methodName(param1, operationID);
}
```

**B) New callback method → event:**

Android `AdvancedMsgListener.java`:
```java
@Override
public void onRecvXxx(String s) {
  send(ctx, "onRecvXxx", jsonStringToMap(s));
}
```

iOS `OpenImSdkRn.m` — add to `supportedEvents` array:
```objc
@"onRecvXxx",
```
iOS `OpenImSdkRn.m` — add handler method:
```objc
- (void)onRecvXxx:(NSString *)message {
  [self sendEventWithName:@"onRecvXxx" body:message];
}
```

TypeScript `src/constants/OpenIMEvents.ts`:
```ts
OnRecvXxx: 'onRecvXxx',
```

TypeScript `src/types/eventArgs.ts`:
```ts
[OpenIMEvent.OnRecvXxx]: [data: XxxType];
```

**C) New/updated struct field → TypeScript type update:**

Find the existing TypeScript type in `entity.ts` using the mapping table.
Add the new field using the type mapping table.
If the struct is brand new, add the complete type definition.

---

## Step 10 — Summary report

After all edits, print a report:

```
=== Bridge Update Summary ===
New functions bridged:       X  (list names)
New callbacks/events added:  X  (list names)
New/updated TS types:        X  (list names)
Breaking changes flagged:    X  (list with description)
Manual review needed:        X  (list with reason)
```

---

## Error handling

- If `make android` or `make ios` fails, stop and show the error output. Do not copy or continue.
- If either artifact is missing after the build, stop and report.
- If `.last-core-tag` does not exist (first build ever), do a full read of all Go source files (`open_im_sdk/`, `open_im_sdk_callback/callback_client.go`, `sdk_struct/sdk_struct.go`, `pkg/sdk_params_callback/`) and compare against current bridge files manually instead of diffing.
- If a Go struct is not in the mapping table and the name is ambiguous, add the TS type with `// TODO: verify mapping` and flag it in the summary.
- If a Go function signature uses a type not yet mapped to TypeScript, use `unknown` and flag it.
