# Project Changelog

All notable changes to `open-im-sdk-reactnative` are documented here.

Format: `v<SDK_VERSION>` — `openimsdk-core <CORE_TAG>` — `<DATE>`

---

## Unreleased — openimsdk-core `feat/sdk-network-log-debug` (droppii/openimsdk-core#85)

**New API. Bridge updated. Fixes three methods that threw at runtime.**

### Added
- `OpenIMEvent.OnNetworkLog` → `logJSON: string` (`NetworkLogEntry`) — debug-only stream of the core's HTTP (`POST`), WS (`WS`), server push (`PUSH`) and heartbeat (`PING`) traffic, for Reactotron
- `InitOptions.networkLogEnabled` — enables the stream at `initSDK`; pass `__DEV__`. The listener is only registered in debug (iOS) / debuggable (Android) app builds
- `getUserStatus(userIDList)` → `UserOnlineState[]`
- `getSdkVersion()` → `string`
- `getAtAllTag()` → `string`
- `searchConversation(keyword)` → `ConversationItem[]`
- `createAdvancedTextMessage(AdvancedMsgParams)` / `createAdvancedQuoteMessage(AdvancedQuoteMsgParams)` → `MessageItem`
- `markMessagesAsReadByMsgID(MarkMsgsAsReadParams)` (Android bridge added; iOS already existed)
- `hideAllConversations()`

### Changed
- `networkStatusChanged()` now calls the native `networkStatusChange` — it previously rejected on every call, so the core was never told about network changes
- `hideAllConversation()` → deprecated alias of `hideAllConversations()` (it previously called a non-existent native method)
- `updateFriends()` now bridged on iOS and Android (`@ReactMethod` was missing on Android, iOS had no method)
- `UpdateFriendsParams.remark` / `ex` typed `string` (were `boolean`)

---

## v1.0.0-rc49 — openimsdk-core 0.0.1-rc40 — 2026-10-07

**Internal fixes only. No bridge API changes.**

- `GetFirstUnreadMessage` idle timeout now configurable from server (`unreadIndicatorIdleSeconds`) instead of hardcoded 5 days

---

## v1.0.0-rc45 — openimsdk-core 0.0.1-rc38 — 2026-10-05

**Internal fixes only. No bridge API changes.**

- Extension type check made case-insensitive; added `"custom_message_event"` allowed extension
- Removed `filterBotGroupNotificationMsgs` (no longer needed)
- Fixed context propagation in `SetMessageLocalEx`
- Improved unjoined group conversation handling in message history pull

---

## v1.0.0-rc44 — openimsdk-core 0.0.1-rc37 — 2026-10-02

**Internal fixes only. No bridge API changes.**

---

## v1.0.0-rc43 — openimsdk-core 0.0.1-rc36 — 2026-09-30

**Internal fixes only. No bridge API changes.**

- `GetFirstUnreadMessage` now skips messages before user joined a group (minSeq filtering)
- `markConversationMessageAsRead` auto-syncs `hasReadSeq` when `unreadCount == 0` but cursor is behind

---

## v1.0.0-rc42 — openimsdk-core 0.0.1-rc35 — 2026-09-30

**New API. Bridge updated.**

### Added
- `getFirstUnreadMessage(conversationID)` → `GetFirstUnreadMessageResult` — returns the first unread message in a conversation for showing an unread indicator
- `ConversationItem.lastOpenTime?: number` — timestamp of when the conversation was last opened (used by the unread indicator)
- `GetFirstUnreadMessageResult` type in `src/types/entity.ts`

---

## v1.0.0-rc41 — 2026-09-22

No core sync. Internal SDK maintenance.

---

## v1.0.0-rc40 — openimsdk-core 0.0.1-rc32 — 2026-09-17

Internal fixes. No bridge API changes.

---

## v1.0.0-rc39 — 2026-09-08

Internal SDK maintenance.

---

## v1.0.0-rc38 — openimsdk-core 0.0.1-rc29 — 2026-09-03

Internal fixes. No bridge API changes.

---

## v1.0.0-rc37 — openimsdk-core 0.0.1-rc28 — 2026-09-03

Internal fixes. No bridge API changes.

---

## v1.0.0-rc35 — openimsdk-core 0.0.1-rc26 — 2026-08-28

Internal fixes. No bridge API changes.

---

## v1.0.0-rc31 — 2026-08-21

Internal SDK maintenance.

---

## v1.0.0-rc30 — openimsdk-core 0.0.1-rc23 — 2026-08-21

Internal fixes. No bridge API changes.

---

## v1.0.0-rc18 and earlier

Initial release series. Core bridge implementation.
