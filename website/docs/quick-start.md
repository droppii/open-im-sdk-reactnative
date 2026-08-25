---
id: quick-start
title: Quick Start
sidebar_position: 2
---

# Quick Start

## 1. Initialize the SDK

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

## 2. Subscribe to Connection Events

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

## 3. Login

Your OpenIM server must issue a user token. Never hardcode tokens.

```typescript
await OpenIMSDK.login({
  userID: 'user-id-from-your-auth',
  token: 'jwt-token-from-your-openim-server'
});
```

## 4. Send & Receive Messages

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

## 5. Cleanup

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

See [System Architecture](/system-architecture) for the complete `MessageType` reference table.

### operationID

Every API call accepts an optional `operationID` string (auto-generated UUID if omitted). Used for backend log queries and tracing.

### Event Subscription

Use `OpenIMSDK.on(EventName, callback)` and `OpenIMSDK.off(EventName, callback)`. The SDK manages native `EmitterSubscription`s correctly, including cleanup.

## Example App

A working example harness (live-linked to `src/` during development) is in `example/` in the repo. To run it:

```sh
yarn
yarn example ios    # or: yarn example android
```

**Note:** The example app is a dev harness, not an npm-install consumer example. Real integration uses `npm install @droppii/openim-rn-client-sdk` + iOS pod install.

## Troubleshooting

**iOS build failures:** See the [iOS build troubleshooting guide](https://github.com/droppii/open-im-sdk-reactnative/blob/main/docs/IOS-EXAMPLE-WARN.md) for common solutions.
