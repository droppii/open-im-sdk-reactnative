---
id: project-overview
title: Project Overview
sidebar_position: 3
---


## Executive Summary

`@droppii/openim-rn-client-sdk` is a fully-typed React Native bridge to the OpenIM instant messaging platform. It exposes the Go-based OpenIM SDK core (compiled to native Android and iOS via gomobile) as a JavaScript API for React Native applications.

**Purpose:** Enable React Native developers to integrate peer-to-peer and group messaging into their apps with a single npm install, leveraging a self-hosted OpenIM server as the backend.

---

## What This Package Is

1. **A Bridge, Not a Framework**
   - Wraps the native OpenIM SDK core (Go compiled to AAR/xcframework)
   - Exposes ~60 typed TypeScript methods
   - Handles async/await conversion from native callback-based APIs
   - Manages real-time event subscriptions

2. **Production-Ready for Messaging**
   - 60+ API methods for user, friend, group, conversation, and message operations
   - Real-time event delivery (message receive, typing status, group changes, friend requests)
   - SQLite-backed local storage (managed by the Go core, transparent to JS)
   - Message type support: text, images, video, audio, files, location, custom payloads, reactions, etc.

3. **Fully Typed**
   - Complete TypeScript definitions for all APIs, params, and event payloads
   - Enums for `MessageType`, `GroupMemberRole`, `MessageReceiveOptType`, `LoginStatus`, etc.
   - Type hints guide developers from IDE autocompletion

---

## What This Package Is NOT

- **Not a UI Kit:** No chat bubble, message input, contact list, or group management UI components included
- **Not a Content Delivery Network:** File uploads are passed through to the OpenIM server's OSS integration (e.g., AWS S3, Aliyun)
- **Not a Backend Server:** Requires an external self-hosted OpenIM server for authentication and message routing
- **Not Database Agnostic:** Uses SQLite exclusively (hardcoded in the Go core)

---

## Scope & Boundaries

### In Scope

| Area | Details |
|------|---------|
| **Authentication** | Login, logout, token refresh, connection state management |
| **Messaging** | Send/receive text, images, video, files, custom messages; message history; message revocation |
| **Conversations** | List, search, mute, pin, delete; draft tracking; unread count |
| **Users** | Profile fetch/update, online status subscriptions, user info queries |
| **Friends** | Add, delete, block, list; friend application workflow (request → accept/reject) |
| **Groups** | Create, join, invite, member management, owner/admin roles, permissions, info updates |
| **Real-Time Events** | ~45 event types covering connections, messages, friend/group changes, typing status, sync progress |
| **Local Storage** | Message history, conversation state, user info (all SQLite, transparent) |
| **File Upload** | Integration point with server-side OSS (upload progress tracking, completion) |

### Out of Scope

- Chat UI rendering
- File download/caching strategy
- End-to-end encryption (delegated to server)
- Call/video integration (separate SDKs)
- Message search beyond local SQLite queries
- User presence beyond online/offline binary state

---

## Functional Requirements

### 1. SDK Initialization & Lifecycle
- [ ] Initialize with server addresses (API HTTP, WebSocket), local data directory, log settings
- [ ] Cleanly teardown with `unInitSDK()` (disconnect, close DB, stop listeners)
- [ ] Handle network interruptions and auto-reconnection

### 2. User Authentication
- [ ] Accept `userID` + JWT token from consuming app's auth server
- [ ] Emit `OnConnecting` → `OnConnectSuccess` / `OnConnectFailed` lifecycle events
- [ ] Provide `getLoginStatus()` and `getLoginUserID()` queries
- [ ] Manage `OnUserTokenExpired` / `OnUserTokenInvalid` scenarios

### 3. Real-Time Messaging
- [ ] Create message objects (text, image, video, file, location, custom, etc.)
- [ ] Send messages (1-to-1 and group) with callback → Promise resolution
- [ ] Receive messages in real-time via `OnRecvNewMessage` / `OnRecvNewMessages`
- [ ] Emit `SendMessageProgress` event during upload (for media-heavy messages)
- [ ] Support message revocation, deletion, and local-only deletion

### 4. Conversation Management
- [ ] List all conversations or paginated split (offset/count)
- [ ] Query by ID, session type (single/group)
- [ ] Mark as read, pin/unpin, set draft text
- [ ] Get unread message count (per-conversation and total)
- [ ] Delete with/without message history

### 5. User & Status
- [ ] Fetch self info and other users' public info
- [ ] Update own profile (avatar, nickname, bio, etc.)
- [ ] Subscribe to online status of specific users
- [ ] Receive `OnUserStatusChanged` events

### 6. Friend Management
- [ ] Add friend (with optional remark)
- [ ] List friends with pagination
- [ ] Block/unblock users
- [ ] Handle friend application workflow: send request → receive notification → accept/reject
- [ ] Search friends by keyword

### 7. Group Management
- [ ] Create group (specify members, type, info)
- [ ] Join public groups (via keyword search or QR code)
- [ ] Invite specific users to existing groups
- [ ] Manage membership: kick, mute/unmute members, transfer ownership
- [ ] Update group info (name, avatar, description, announcement)
- [ ] Receive group change notifications via `OnGroupInfoChanged`, `OnGroupMemberAdded`, etc.

### 8. Message Types & Events
- [ ] Correctly route system notifications (MessageType >= 1200) to dedicated events, not `OnRecvNewMessage`
- [ ] Support content type routing: TextMessage, PictureMessage, VideoMessage, FileMessage, CustomMessage, etc.
- [ ] Emit 45+ event types covering connection, message, friend, group, and sync topics

### 9. Error Handling
- [ ] All async APIs throw `OpenIMApiError` with `{code, message, operationID}`
- [ ] Distinguish native errors from SDK errors
- [ ] Provide operation tracing via optional `operationID` parameter

---

## Non-Functional Requirements

### Performance
- **Message Delivery Latency:** < 500ms (server-dependent)
- **Memory:** Minimal overhead on top of native SDK (JS bridge ~5–10 MB resident)
- **DB Size:** SQLite growth depends on message volume; typical: 10 MB per 10K messages

### Reliability
- **Connection Auto-Reconnect:** Yes, implemented in Go core
- **Message Queuing:** Failed sends queued by Go core, retried on reconnect
- **Event Delivery:** No guaranteed-once; app should handle idempotency

### Type Safety
- **TypeScript:** All APIs, types, enums fully typed; no `any` in public surface
- **Runtime Validation:** Native layer validates params; JS raises `OpenIMApiError` on rejection

### Accessibility
- **Documentation:** Full API reference, type definitions, example code
- **Error Messages:** Human-readable; include operation ID for backend log queries
- **Backward Compatibility:** operationID made optional in v1.0.0-rc30+ (auto-generated if omitted)

---

## Acceptance Criteria

### API Reference Complete
- [ ] All 60+ methods documented with param types and return types
- [ ] All 45+ events documented with payload types
- [ ] All 22 enums documented with value meanings
- [ ] Message type routing table explains which event delivers each MessageType

### Developer Experience
- [ ] TypeScript types cover all public APIs (no `any` leakage)
- [ ] Example app (in `example/`) demonstrates init, login, send, receive, group operations
- [ ] Quick start guide in README under 300 lines
- [ ] API reference comprehensive enough to find any method/event in < 30 seconds

### Reliability
- [ ] Unit tests pass on both Android and iOS
- [ ] No memory leaks over 1-hour runtime (native + JS)
- [ ] Error handling for all failure modes (network, auth, permission, not found, etc.)
- [ ] Graceful shutdown (logout → unInitSDK) cleans all listeners and native resources

### Platform Coverage
- [ ] iOS 12.0+ supported (via Podspec)
- [ ] Android 6.0+ (API 21+) supported (via build.gradle)
- [ ] Expo prebuild workflow functional

---

## Success Metrics

1. **Adoption:** npm downloads > 100/month; positive feedback on TypeScript experience
2. **Documentation:** No "How do I..." issues; developers find answers in docs/
3. **Support Burden:** < 5 issues/month related to API misuse (vs. bugs)
4. **Stability:** < 1 crash per 1000 sessions (after GA release)
5. **Build Success:** 95%+ successful installs via npm + pod install (iOS) without manual intervention

---

## Dependencies & Constraints

### External Dependencies
- React Native v0.72+ (NativeModule system)
- OpenIM server (self-hosted; URL provided at init time)
- Platform SDKs: Xcode (iOS), Android Studio (Android)

### Build Pipeline
- Upstream `openimsdk-core` Go SDK (maintained separately)
- gomobile compiler (generates AAR/xcframework from Go source)
- Native artifacts stored in `native-libs/` (pre-compiled, vendored)
- Release via `release-openim-sdk` skill (see `docs/deployment-guide.md`)

### Known Limitations
- Android & iOS `CustomBusinessListener` / `OnSignalingListener` not wired up (stub in code)
- Some `UploadFileCallbackProxy` sub-callbacks are no-ops
- `UserListener` lifecycle events (`onUserCommandAdd/Delete/Update`) implemented but not exposed to JS
- File download streaming not exposed; files downloaded on-demand by app from server-provided URLs

---

## Timeline & Roadmap

This package is a **wrapper maintained in sync with upstream OpenIM**. No independent feature roadmap.

- **Releases:** Follow `openimsdk-core` version bumps (e.g., core 0.0.1-rc23 → SDK v1.0.0-rc30)
- **Maintenance:** Keep TypeScript types, bridges (Android/iOS), and docs current with upstream changes
- **Deprecations:** Announced 2 releases in advance; supported for 3 releases minimum

See `docs/project-roadmap.md` for current phase status.

---

## Stakeholders

- **Developers:** Integrate this SDK into React Native apps
- **OpenIM Community:** Upstream Go SDK maintainers
- **Droppii:** Package maintainer, release process owner
