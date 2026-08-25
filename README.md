# React Native Client SDK for OpenIM

A fully-typed React Native wrapper around the OpenIM chat SDK's Go core, compiled to native Android (AAR) and iOS (xcframework) artifacts via gomobile.

## What This SDK Is

A production-ready bridge that exposes the OpenIM chat backend's core messaging, user, group, and conversation APIs to JavaScript through React Native's native modules system. It includes:

- 60+ typed TypeScript methods for chat operations
- Real-time event subscriptions (connections, messages, friend/group changes, typing indicators, etc.)
- Full support for message types: text, images, video, files, voice, location, custom, reactions, and more
- Conversation & friend list management
- Group creation, membership, and administration
- SQLite-backed local message storage (managed by the Go core)

**What it is NOT:** A UI kit — this SDK handles all backend integration and data persistence, but no chat bubble rendering, input controls, or UI components are included. You bring your own React Native UI.

## Installation

### React Native CLI

```sh
npm install @droppii/openim-rn-client-sdk
cd ios && pod install && cd ..
```

### Expo (Custom Dev Client)

Supported from v1.0.0-rc30+ via the prebuild workflow. Expo Go is not supported (this package uses native modules).

```sh
npm install @droppii/openim-rn-client-sdk
npx expo prebuild
npx expo run:android      # or npx expo run:ios
```

## Quick Start

### 1. Initialize the SDK

```typescript
import OpenIMSDK from '@droppii/openim-rn-client-sdk';
import RNFS from 'react-native-fs';

// Create data directory first
await RNFS.mkdir(RNFS.DocumentDirectoryPath + '/tmp');

// Initialize
await OpenIMSDK.initSDK({
  apiAddr: 'http://<your-openim-server>:10002',
  wsAddr: 'ws://<your-openim-server>:10001',
  dataDir: RNFS.DocumentDirectoryPath + '/tmp',
  logFilePath: RNFS.DocumentDirectoryPath + '/tmp',
  logLevel: 5,
  isLogStandardOutput: true,
}, 'my-operation-id');
```

### 2. Subscribe to Connection Events

```typescript
import { OpenIMEvent } from '@droppii/openim-rn-client-sdk';

OpenIMSDK.on(OpenIMEvent.OnConnecting, () => {
  console.log('Connecting...');
});

OpenIMSDK.on(OpenIMEvent.OnConnectSuccess, () => {
  console.log('Connected!');
});

OpenIMSDK.on(OpenIMEvent.OnConnectFailed, ({ errCode, errMsg }) => {
  console.log(`Failed: ${errCode} - ${errMsg}`);
});
```

### 3. Login

Your OpenIM server must issue a user token. Never hardcode tokens.

```typescript
await OpenIMSDK.login({
  userID: 'user-id-from-your-auth',
  token: 'jwt-token-from-your-openim-server'
});
```

### 4. Send & Receive Messages

```typescript
// Listen for incoming messages
OpenIMSDK.on(OpenIMEvent.OnRecvNewMessage, (message) => {
  console.log('Message received:', message.contentType, message.content);
});

// Create a message
const msg = await OpenIMSDK.createTextMessage('Hello!');

// Send to a user (1-to-1 chat)
await OpenIMSDK.sendMessage({
  recvID: 'recipient-user-id',
  groupID: '',  // empty for direct messages
  message: msg,
});

// Send to a group
await OpenIMSDK.sendMessage({
  recvID: '',  // empty for group messages
  groupID: 'group-id',
  message: msg,
});
```

### 5. Cleanup

```typescript
OpenIMSDK.off(OpenIMEvent.OnRecvNewMessage, handlerRef);
await OpenIMSDK.logout();
await OpenIMSDK.unInitSDK();
```

## Key Concepts

### Message Types

Messages carry a `contentType` field (enum `MessageType`) that determines which event fires:
- **101–162**: Regular chat messages (text, image, video, file, sticker, etc.) → `OnRecvNewMessage`
- **1200+**: System notifications (group created, member added, friend accepted, etc.) → dedicated events (`OnGroupInfoChanged`, `OnFriendAdded`, etc.)

See `docs/system-architecture.md` for the complete `MessageType` reference table.

### operationID

Every API call accepts an optional `operationID` string (auto-generated UUID if omitted). Used for backend log queries and tracing.

### Event Subscription

Use `OpenIMSDK.on(EventName, callback)` and `OpenIMSDK.off(EventName, callback)`. The SDK manages native `EmitterSubscription`s correctly, including cleanup.

## Platform Requirements

- **React Native:** v0.72+
- **iOS:** 12.0+
- **Android:** 6.0+ (API 21+)

## Documentation

- **Full API Reference & Usage Examples:** [docs/codebase-summary.md](./docs/codebase-summary.md)
- **System Architecture & Message Type Table:** [docs/system-architecture.md](./docs/system-architecture.md)
- **Code Standards for Contributors:** [docs/code-standards.md](./docs/code-standards.md)
- **Deployment & Integration:** [docs/deployment-guide.md](./docs/deployment-guide.md)
- **Project Overview & PDR:** [docs/project-overview-pdr.md](./docs/project-overview-pdr.md)

## Troubleshooting

**iOS build failures:** See [docs/IOS-EXAMPLE-WARN.md](./docs/IOS-EXAMPLE-WARN.md) for common solutions.

## Example App

A working example harness (live-linked to `src/` during development) is in `example/`. To run it:

```sh
yarn
yarn example ios    # or: yarn example android
```

**Note:** The example app is a dev harness, not an npm-install consumer example. Real integration uses `npm install @droppii/openim-rn-client-sdk` + iOS pod install.

## License

Apache 2.0 — see [LICENSE](./LICENSE).
