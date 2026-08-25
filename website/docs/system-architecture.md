---
id: system-architecture
title: System Architecture
sidebar_position: 4
---


## Overview

The React Native SDK bridges JavaScript to OpenIM's Go core through native Android (Java) and iOS (Objective-C) modules. Native code handles JSON serialization, callback-to-promise adaptation, and event subscription routing. All communication is callback-based at the native layer, then wrapped into Promises and RxJS-like events at the JS layer.

---

## Bridge Architecture

### Request Flow: JS → Native → Go → Native → Promise

```
JavaScript App
    ↓
OpenIMSDK.methodName(params, operationID)
    ↓ (calls)
NativeOpenIMSDK.methodName(...)  [raw native module ref]
    ↓ (Android: RCTNativeModule.java @ReactMethod)
    ↓ (iOS: OpenImSdkRn.m RCT_EXPORT_METHOD)
    ↓
Serialize params to JSON string (ReadableMap.toString() / NSJSONSerialization)
Create callback proxy (BaseImpl / RNCallbackProxy)
    ↓
Call gomobile-generated Go function: Open_im_sdk.methodName(...)
    ↓
Go core processes request, calls callback proxy
    ↓
Callback proxy receives JSON result string
    ↓
Deserialize JSON → JS native object
    ↓
Resolve Promise with result object
    ↓
JavaScript awaits completion
```

**Key Detail:** Go SDK is inherently callback-based (synchronous methods like `getLoginStatus()` return directly; async methods invoke `callback.onSuccess(jsonString)` / `callback.onError(code, msg)` on a background Go goroutine). The bridge adapts each callback into a Promise that resolves/rejects on the JS side.

**Synchronous Methods** (no callback needed; return result directly):
- `getLoginStatus()` → `LoginStatus` enum value
- `getLoginUserID()` → user ID string
- `isJoinGroup(groupID)` → boolean

**Message Send Special Case:** `sendMessage()` / `sendMessageNotOss()` emit an extra progress event (`SendMessageProgress`) during upload, independent of the promise. A specialized callback proxy (`SendMsgCallBack` / `RNSendMessageCallbackProxy`) wires the progress callback to an event and the completion callback to the promise.

**File Upload Progress:** Similarly, `uploadFile()` uses a multi-step proxy that emits `UploadOnProgress` events and `UploadComplete` on finish, separate from the promise.

---

## Event Flow: Native → JS Event Emitter

### At SDK Initialization

When `initSDK()` is called, the bridge registers long-lived listener callbacks with every Go SDK listener interface:

- `SetUserListener` (user info, status, token expiry)
- `SetConversationListener` (conversation changes, unread counts, sync events)
- `SetFriendListener` (friend additions, deletions, applications)
- `SetGroupListener` (group info changes, membership changes)
- `SetAdvancedMsgListener` (message receive, delivery receipts, revocation)
- `SetBatchMsgListener` (batch message operations)

These listeners remain active for the SDK's lifetime, receiving callbacks from background Go threads.

### When an Event Fires

1. **Go Thread:** Go SDK invokes listener method (e.g., `onRecvNewMessage(jsonString)`)
2. **Native Bridge:** Deserialize JSON to native object
3. **Android:** `RCTDeviceEventEmitter.emit("eventName", dataObj)` (via `Emitter.send()`)
4. **iOS:** `RCTEventEmitter.sendEventWithName("eventName", body:...)` (dispatched to main thread via `pushEvent:data:`)
5. **JS Event Emitter:** `NativeEventEmitter(NativeOpenIMSDK)` receives event
6. **JS App:** Callbacks registered via `OpenIMSDK.on(EventName, callback)` fire synchronously

**Thread Safety:** Android events post to RN's thread pool; iOS events dispatch to main thread. JS callbacks execute on RN's JS thread.

---

## Component Breakdown

### `src/` (JavaScript/TypeScript Layer)

| File | Purpose |
|------|---------|
| `sdk.ts` | Main `OpenIMSDK` class; all 60+ methods; singleton pattern |
| `emitter.ts` | Event emitter wrapper; `on()` / `off()` with native subscription tracking |
| `OpenIMSDK.native.ts` | Raw native module interface; lowest-level bridge |
| `types/entity.ts` | Data shapes: `MessageItem`, `ConversationItem`, `GroupItem`, `UserInfo`, etc. |
| `types/params.ts` | Request parameter types for all methods |
| `types/enum.ts` | Enums: `MessageType`, `GroupMemberRole`, `LoginStatus`, etc. (22 enums total) |
| `types/eventArgs.ts` | Event payload shapes |
| `constants/OpenIMEvents.ts` | Event name constants |
| `errors/OpenIMApiError.ts` | Exception class for API failures |
| `utils/id.ts` | UUID v4 generator for `operationID` |

**Total:** ~2700 LOC across 12 files.

### `android/` (Java Bridge)

| File | Purpose |
|------|---------|
| `OpenImSdkRnModule.java` | Main module; `@ReactMethod` decorators for each public SDK method |
| `Emitter.java` | Wrapper around `RCTDeviceEventEmitter` |
| `BaseImpl.java` / `SendMsgCallBack.java` / `UploadFileCallbackProxy.java` | Callback proxy classes (inherit from gomobile-generated callback interfaces) |
| `OpenImSdkRnPackage.java` | Package registration for RN |

**Total:** ~2000 LOC across 16 files.

### `ios/` (Objective-C Bridge)

| File | Purpose |
|------|---------|
| `OpenImSdkRn.m` | Main module; `RCT_EXPORT_METHOD` for each public SDK method |
| `RNCallbackProxy.h/m` | Generic callback proxy class |
| `RNSendMessageCallbackProxy.h/m` | Specialized for message send progress tracking |
| `RNUploadFileCallbackProxy.h/m` / `RNUploadLogCallbackProxy.h/m` | Upload progress tracking |
| `NSMutableDictionary+JSON.h/m` | Category for JSON serialization (duplicated across multiple files — technical debt) |

**Total:** ~2000 LOC across 10 files.

### `native-libs/` (Pre-compiled Native Artifacts)

- `android/open_im_sdk.aar` — gomobile-compiled Android Archive (Go + JNI glue)
- `ios/OpenIMCore.xcframework` — gomobile-compiled iOS XCFramework (Go + Objective-C bridging header)

Both are **vendored binaries**, versioned in git (not built from source in this repo). Rebuilt via the `release-openim-sdk` skill from the upstream `openimsdk-core` Go repository.

---

## Type Mapping Patterns

### Go → TypeScript Type Conversion

The `release-openim-sdk` skill generates TS types from Go struct definitions. Common patterns:

| Go Type | TypeScript Type |
|---------|-----------------|
| `string` | `string` |
| `int32`, `int64` | `number` |
| `bool` | `boolean` |
| `[]string` | `string[]` |
| `time.Time` (epoch ms) | `number` |
| Struct fields | Object properties (snake_case → camelCase) |
| Enums (iota) | Numeric enums |

**Example:** Go struct `type UserInfo { UserID string; Nickname string; }` → TS type `{ userID: string; nickname: string }`.

---

## Message Type Routing Table

**Critical for developers:** A message's `contentType` field (enum `MessageType`) determines which event fires. **This is the single most important piece of documentation for SDK users.**

### Chat Messages (101–162) → `OnRecvNewMessage` / `OnRecvNewMessages`

| Value | Name | Meaning | Message Element |
|-------|------|---------|-----------------|
| 101 | `TextMessage` | Plain text chat | `TextElem` |
| 102 | `PictureMessage` | Image (photo, screenshot, etc.) | `PictureElem` |
| 103 | `VoiceMessage` | Audio/voice memo | `SoundElem` |
| 104 | `VideoMessage` | Video clip | `VideoElem` |
| 105 | `FileMessage` | Any file (doc, pdf, zip, etc.) | `FileElem` |
| 106 | `AtTextMessage` | Text with @mentions (group only) | `AtTextElem` |
| 107 | `MergeMessage` | Forwarded message thread | `MergeElem` |
| 108 | `CardMessage` | User/group card (contact share) | `CardElem` |
| 109 | `LocationMessage` | Geographic coordinates (map) | `LocationElem` |
| 110 | `CustomMessage` | App-defined JSON payload | `CustomElem` |
| 111 | `RevokedMessage` | Placeholder (original revoked) | `RevokedElem` |
| 113 | `TypingMessage` | "User is typing…" indicator | (transient; not stored) |
| 114 | `QuoteMessage` | Reply to another message | `QuoteElem` |
| 115 | `FaceMessage` | Emoji/sticker reaction | `FaceElem` |
| 117 | `AdvancedTextMessage` | Text with rich formatting (markdown-like) | `AdvancedTextElem` |
| 118 | `MarkdownTextMessage` | Markdown-formatted text | `AdvancedTextElem` |
| 119 | `CustomNotTriggerConversation` | Custom payload; doesn't create conversation | `CustomElem` |
| 120 | `CustomOnlineOnlyMessage` | Custom payload; online-only (not stored) | `CustomElem` |
| 121 | `ReactionMessageModifier` | Reaction added to a message | (internal; not chat message) |
| 122 | `ReactionMessageDeleter` | Reaction removed from a message | (internal; not chat message) |
| 160 | `UrlTextMessage` | Text with embedded URLs | `AdvancedTextElem` |
| 161 | `LogTextMessage` | Diagnostic/log message | `AdvancedTextElem` |
| 162 | `StickerMessage` | Sticker pack item | `StickerElem` |

**Payload Structure:** Each `MessageItem` contains one populated `*Elem` field per type:

```typescript
interface MessageItem {
  contentType: MessageType;  // e.g., 101 (TextMessage)
  textElem?: TextElem;       // populated if type=101
  pictureElem?: PictureElem; // populated if type=102
  // ... one field per type
}

interface TextElem {
  content: string;           // message body
  ex?: string;               // app-defined extra data
}

interface AtTextElem {
  text: string;              // message body with @ symbols
  atUserList: string[];      // mentioned user IDs
  isAtAll: boolean;          // @all mention flag
  atAllExt?: string;         // extra data for @all
}
```

### Friend System Notifications (1201–1210) → `OnFriendAdded`, etc.

| Value | Name | Meaning | Event |
|-------|------|---------|-------|
| 1201 | `FriendAdded` | Bidirectional friend relation established | `OnFriendAdded` |
| 1202 | `FriendApplicationRejected` | User rejected friend request | `OnFriendApplicationRejected` |
| 1203 | `FriendApplicationReceived` | User received friend request | `OnFriendApplicationAdded` |
| 1204 | `FriendAddSuccess` | (unused; duplicate of 1201) | — |
| 1205 | `FriendDeleted` | Friend relation deleted | `OnFriendDeleted` |
| 1206 | `FriendRemarkSet` | Friend remark updated | `OnFriendInfoChanged` |
| 1207 | `BlackAdded` | User added to block list | `OnBlackAdded` |
| 1208 | `BlackDeleted` | User removed from block list | `OnBlackDeleted` |
| 1209 | `FriendInfoUpdated` | Friend's public info changed | `OnFriendInfoChanged` |
| 1210 | `FriendsInfoUpdate` | Multiple friends' info changed | `OnFriendInfoChanged` |

**Note:** These arrive as `MessageItem` objects with `contentType` set to the value above, routed by the SDK to the corresponding event (not `OnRecvNewMessage`).

### User & Conversation Notifications (1300–1308) → `OnSelfInfoUpdated`, etc.

| Value | Name | Meaning | Event |
|-------|------|---------|-------|
| 1303 | `UserInfoUpdated` | Self user info changed | `OnSelfInfoUpdated` |
| 1304 | `UserStatusChanged` | User online/offline status changed | `OnUserStatusChanged` |
| 1305 | `UserCommandAdd` | User command added | (internal; not exposed) |
| 1306 | `UserCommandDelete` | User command deleted | (internal; not exposed) |
| 1307 | `UserCommandUpdate` | User command updated | (internal; not exposed) |
| 1308 | `UserSubscribeOnlineStatus` | Online status subscription changed | (internal; not exposed) |
| 1300 | `ConversationChanged` | Conversation properties changed | `OnConversationChanged` |

### OA/Notification (1400) → `OnRecvCustomBusinessMessage`

| Value | Name | Meaning | Event |
|-------|------|---------|-------|
| 1400 | `OANotification` | Official account notification | `OnRecvCustomBusinessMessage` |

### Group Notifications (1501–1520) → `OnGroupInfoChanged`, `OnGroupMemberAdded`, etc.

| Value | Name | Meaning | Event |
|-------|------|---------|-------|
| 1501 | `GroupCreated` | Group created by user | `OnGroupInfoChanged` / `OnJoinedGroupAdded` |
| 1502 | `GroupInfoUpdated` | Group name/avatar/desc changed | `OnGroupInfoChanged` |
| 1503 | `JoinGroupApplication` | User applied to join group | `OnGroupApplicationAdded` |
| 1505 | `GroupApplicationAccepted` | Admin accepted user's join request | `OnGroupApplicationAccepted` |
| 1506 | `GroupApplicationRejected` | Admin rejected user's join request | `OnGroupApplicationRejected` |
| 1507 | `GroupOwnerTransferred` | Ownership transferred to new user | `OnGroupInfoChanged` |
| 1508 | `MemberKicked` | User kicked from group | `OnGroupMemberDeleted` |
| 1509 | `MemberInvited` | User invited to group | `OnGroupMemberAdded` |
| 1510 | `MemberEnter` | User joined group voluntarily | `OnGroupMemberAdded` |
| 1511 | `GroupDismissed` | Group dissolved by owner | `OnGroupDismissed` |
| 1512 | `GroupMemberMuted` | Member muted (cannot send messages) | `OnGroupMemberInfoChanged` |
| 1513 | `GroupMemberCancelMuted` | Member mute lifted | `OnGroupMemberInfoChanged` |
| 1514 | `GroupMuted` | Entire group muted | `OnGroupInfoChanged` |
| 1515 | `GroupCancelMuted` | Group mute lifted | `OnGroupInfoChanged` |
| 1516 | `GroupMemberInfoSet` | Member info updated (nickname, role) | `OnGroupMemberInfoChanged` |
| 1517 | `GroupMemberSetToAdmin` | Member promoted to admin | `OnGroupMemberInfoChanged` |
| 1518 | `GroupMemberSetToOrdinaryUser` | Member demoted to regular user | `OnGroupMemberInfoChanged` |
| 1519 | `GroupAnnouncementUpdated` | Group announcement changed | `OnGroupInfoChanged` |
| 1520 | `GroupNameUpdated` | Group name changed | `OnGroupInfoChanged` |

### Misc Notifications (1651–1703)

| Value | Name | Meaning | Event |
|-------|------|---------|-------|
| 1651 | `SuperGroupUpdated` | Super group (large group) updated | (internal; not exposed) |
| 1652 | `MsgDeleted` | Message deleted (all devices) | `OnMsgDeleted` |
| 1701 | `BurnMessageChange` | Burn-after-read duration changed | (internal; not exposed) |
| 1702 | `ConversationUnread` | Conversation unread status changed | `OnTotalUnreadMessageCountChanged` |
| 1703 | `ClearConversation` | Conversation cleared locally | `OnConversationChanged` |

### Business/Custom Notifications (2001) → `OnRecvCustomBusinessMessage`

| Value | Name | Meaning | Event |
|-------|------|---------|-------|
| 2001 | `BusinessNotification` | Custom business event | `OnRecvCustomBusinessMessage` |

### Protocol Notifications (2101–2200) → Not Direct Messages

| Value | Name | Meaning | Note |
|-------|------|---------|------|
| 2101 | `RevokeMessage` | Message was revoked | Triggers `OnNewRecvMessageRevoked` or `OnMsgDeleted` |
| 2102 | `DeleteMsgs` | Messages deleted | Handled internally |
| 2103 | `PinMsg` | Message pinned | Triggers `OnRecvMessagePinned` |
| 2200 | `HasReadReceipt` | Read receipt received | Triggers `OnRecvC2CReadReceipt` |

**Key Point:** These notification types (2101–2200) are not delivered as `MessageItem` objects to the app; they're intercepted by the SDK and forwarded as their own events. Developers never see a `contentType` of 2101 in `OnRecvNewMessage`.

---

## Known Limitations & Technical Debt

### Not Implemented / Stubbed Out

1. **Android `SetCustomBusinessListener`** / **iOS `OnSignalingListener`**
   - Code paths exist but are never wired to events
   - Reserved for future signaling (call, video) features

2. **`UploadFileCallbackProxy` Sub-Callbacks**
   - Most progress sub-callbacks are no-ops
   - Only completion and upload-complete callbacks are routed to JS

3. **`UserListener` Lifecycle Events**
   - `onUserCommandAdd`, `onUserCommandDelete`, `onUserCommandUpdate` implemented in Go
   - Not exposed to JS (internal only)

4. **iOS JSON Serialization** *(Code Quality Issue)*
   - `NSMutableDictionary+JSON.h/m` category duplicated in multiple files
   - Should be extracted to a shared utility file

---

## Error Handling

All errors thrown from native code are wrapped into `OpenIMApiError` with structure:

```typescript
class OpenIMApiError extends Error {
  code: number;           // error code from native layer
  message: string;        // error message
  operationID: string;    // echoed from request, for backend log lookup
}
```

**Example:**

```typescript
try {
  await OpenIMSDK.login({ userID: 'u1', token: 'invalid' });
} catch (error) {
  if (error instanceof OpenIMApiError) {
    console.log(`Error ${error.code}: ${error.message} (op: ${error.operationID})`);
  }
}
```

---

## Performance Characteristics

| Operation | Latency | Notes |
|-----------|---------|-------|
| Initialization | ~2–5 sec | Opens DB, loads history |
| Login | ~1–3 sec | Network I/O dependent |
| Fetch 100 messages | ~50–200 ms | Local DB query |
| Send message | ~100–500 ms | Network I/O to server |
| Send media message | ~500 ms–10 sec | Depends on file size & upload speed |
| Get friends list | ~100–500 ms | Local DB + JSON serialization |

**Memory:** Resident ~10–50 MB (native SDK + JS objects), scales with cached message volume.

**Database:** SQLite file grows ~10 MB per 10K messages (depends on content types).
