# Project Changelog

All notable changes to `open-im-sdk-reactnative` are documented here.

Format: `v<SDK_VERSION>` — `openimsdk-core <CORE_TAG>` — `<DATE>`

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
