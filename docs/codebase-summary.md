# Codebase Summary & API Reference

## Directory Structure

```
open-im-sdk-reactnative/
├── src/                          # JavaScript/TypeScript bridge layer (~2700 LOC)
│   ├── sdk.ts                    # Main OpenIMSDK class with 60+ methods
│   ├── emitter.ts                # Event subscription wrapper (on/off)
│   ├── OpenIMSDK.native.ts       # Raw native module interface
│   ├── index.tsx                 # Root exports (SDK, emitter, types, errors, events)
│   ├── types/
│   │   ├── entity.ts             # Data shapes: MessageItem, ConversationItem, etc.
│   │   ├── params.ts             # Request parameter types
│   │   └── enum.ts               # 22 enums (MessageType, GroupMemberRole, etc.)
│   ├── types/eventArgs.ts        # Event payload types
│   ├── constants/OpenIMEvents.ts # Event name constants
│   ├── errors/
│   │   ├── OpenIMApiError.ts     # Exception class
│   │   └── OpenIMEventError.ts   # Event error type
│   └── utils/id.ts               # UUID v4 generator
├── android/                       # Java bridge (~2000 LOC)
│   ├── OpenImSdkRnModule.java    # RN module, @ReactMethod methods
│   ├── Emitter.java              # Event emission wrapper
│   ├── BaseImpl.java              # Generic callback proxy
│   ├── SendMsgCallBack.java      # Message send progress tracking
│   ├── UploadFileCallbackProxy.java
│   ├── OpenImSdkRnPackage.java   # RN package registration
│   └── ...
├── ios/                           # Objective-C bridge (~2000 LOC)
│   ├── OpenImSdkRn.m             # RN module, RCT_EXPORT_METHOD methods
│   ├── RNCallbackProxy.h/m       # Generic callback proxy
│   ├── RNSendMessageCallbackProxy.h/m
│   ├── RNUploadFileCallbackProxy.h/m
│   ├── NSMutableDictionary+JSON.h/m (duplicated)
│   └── ...
├── native-libs/                   # Pre-compiled gomobile artifacts
│   ├── android/open_im_sdk.aar   # Android Archive
│   └── ios/OpenIMCore.xcframework # iOS XCFramework
├── example/                       # Dev harness (live-linked to src/)
│   ├── src/App.tsx               # Demo of init, login, send, receive, groups
│   └── ... (full RN project structure)
├── README.md                      # Quick start & installation
└── docs/
    ├── project-overview-pdr.md   # Project scope & requirements
    ├── system-architecture.md    # Bridge design & MessageType table
    ├── code-standards.md         # Patterns & guidelines for contributors
    ├── codebase-summary.md       # This file
    ├── project-roadmap.md        # Phase status & timeline
    └── deployment-guide.md       # Install & integration instructions
```

---

## Public API Reference

### Core Class: `OpenIMSDK`

**Singleton Pattern**

```typescript
import OpenIMSDK from '@droppii/openim-rn-client-sdk';
// or
import { OpenIMSDK } from '@droppii/openim-rn-client-sdk';
const sdk = OpenIMSDK.getInstance();
```

---

## Auth & Initialization

| Method | Params | Returns | Notes |
|--------|--------|---------|-------|
| `initSDK(options, operationID?)` | `InitOptions` | `Promise<void>` | Initialize SDK; must be first call |
| `login(params, operationID?)` | `LoginParams` | `Promise<void>` | Login with userID + JWT token |
| `logout(operationID?)` | — | `Promise<void>` | Disconnect & clear session |
| `unInitSDK(operationID?)` | — | `Promise<void>` | Teardown; disconnect listeners |
| `getLoginStatus(operationID?)` | — | `Promise<LoginStatus>` | **Sync method** — returns enum (1=Logout, 2=Logging, 3=Logged) |
| `getLoginUserID(operationID?)` | — | `Promise<string>` | **Sync method** — logged-in user ID |

**InitOptions:**
```typescript
{
  apiAddr: string;        // HTTP API endpoint (e.g., "http://server:10002")
  wsAddr: string;         // WebSocket endpoint (e.g., "ws://server:10001")
  dataDir: string;        // SQLite database directory (must exist & be writable)
  logFilePath: string;    // Log file directory
  logLevel?: number;      // 0=Panic, 1=Fatal, 2=Error, 3=Warn, 4=Info, 5=Debug
  isLogStandardOutput?: boolean; // Whether to also log to stdout
}
```

**LoginParams:**
```typescript
{
  userID: string;  // User identifier (from your auth system)
  token: string;   // JWT token (issued by your OpenIM server)
}
```

---

## User Management

| Method | Params | Returns |
|--------|--------|---------|
| `getUsersInfo(userIDList, operationID?)` | `string[]` | `Promise<PublicUserItem[]>` |
| `getSelfUserInfo(groupID?, operationID?)` | `string?` | `Promise<SelfUserInfo>` |
| `setSelfInfo(params, operationID?)` | `Partial<SelfUserInfo>` | `Promise<void>` |
| `subscribeUsersStatus(userIDs, operationID?)` | `string[]` | `Promise<UserOnlineState[]>` |
| `unsubscribeUsersStatus(userIDs, operationID?)` | `string[]` | `Promise<void>` |
| `getSubscribeUsersStatus(operationID?)` | — | `Promise<UserOnlineState[]>` |
| `setAppBackgroundStatus(isBackground, operationID?)` | `boolean` | `Promise<void>` |
| `networkStatusChanged(operationID?)` | — | `Promise<void>` |
| `updateFcmToken(fcmToken, expireTime, project?, operationID?)` | `string, number, string?` | `Promise<void>` |
| `setAppBadge(count, project?, operationID?)` | `number, string?` | `Promise<void>` |

---

## Friend Management

| Method | Params | Returns |
|--------|--------|---------|
| `addFriend(params, operationID?)` | `AddFriendParams` | `Promise<void>` |
| `deleteFriend(userID, operationID?)` | `string` | `Promise<void>` |
| `checkFriend(userIDList, operationID?)` | `string[]` | `Promise<FriendshipInfo[]>` |
| `acceptFriendApplication(params, operationID?)` | `AccessFriendParams` | `Promise<void>` |
| `refuseFriendApplication(params, operationID?)` | `AccessFriendParams` | `Promise<void>` |
| `getFriendList(filterBlack, operationID?)` | `boolean` | `Promise<FriendUserItem[]>` |
| `getFriendListPage(params, operationID?)` | `OffsetParams & {filterBlack?}` | `Promise<FriendUserItem[]>` |
| `getSpecifiedFriendsInfo(params, operationID?)` | `GetSpecifiedFriendsParams` | `Promise<FriendUserItem[]>` |
| `updateFriends(params, operationID?)` | `UpdateFriendsParams` | `Promise<void>` |
| `searchFriends(params, operationID?)` | `SearchFriendParams` | `Promise<SearchedFriendsInfo[]>` |
| `setFriendRemark(params, operationID?)` | `RemarkFriendParams` | `Promise<void>` |
| `addBlack(params, operationID?)` | `AddBlackParams` | `Promise<void>` |
| `removeBlack(userID, operationID?)` | `string` | `Promise<void>` |
| `getBlackList(operationID?)` | — | `Promise<BlackUserItem[]>` |
| `getFriendApplicationListAsApplicant(params?, operationID?)` | `GetFriendApplicationListAsApplicantParams?` | `Promise<FriendApplicationItem[]>` |
| `getFriendApplicationListAsRecipient(params?, operationID?)` | `GetFriendApplicationListAsRecipientParams?` | `Promise<FriendApplicationItem[]>` |
| `getFriendApplicationUnhandledCount(params, operationID?)` | `GetSelfApplicationUnhandledCountParams` | `Promise<number>` |

---

## Group Management

| Method | Params | Returns |
|--------|--------|---------|
| `createGroup(params, operationID?)` | `CreateGroupParams` | `Promise<GroupItem>` |
| `joinGroup(params, operationID?)` | `JoinGroupParams` | `Promise<void>` |
| `inviteUserToGroup(params, operationID?)` | `OperateGroupParams` | `Promise<void>` |
| `getJoinedGroupList(operationID?)` | — | `Promise<GroupItem[]>` |
| `getJoinedGroupListPage(params, operationID?)` | `OffsetParams` | `Promise<GroupItem[]>` |
| `searchGroups(params, operationID?)` | `SearchGroupParams` | `Promise<GroupItem[]>` |
| `getSpecifiedGroupsInfo(groupIDs, operationID?)` | `string[]` | `Promise<GroupItem[]>` |
| `setGroupInfo(params, operationID?)` | `SetGroupInfoParams` | `Promise<void>` |
| `dismissGroup(groupID, operationID?)` | `string` | `Promise<void>` |
| `quitGroup(groupID, operationID?)` | `string` | `Promise<void>` |
| `isJoinGroup(groupID, operationID?)` | `string` | `Promise<boolean>` |
| `getGroupMemberList(params, operationID?)` | `GetGroupMemberParams` | `Promise<GroupMemberItem[]>` |
| `getSpecifiedGroupMembersInfo(params, operationID?)` | `GetGroupMembersInfoParams` | `Promise<GroupMemberItem[]>` |
| `getUsersInGroup(params, operationID?)` | `GetGroupMembersInfoParams` | `Promise<GroupMemberItem[]>` |
| `searchGroupMembers(params, operationID?)` | `SearchGroupMemberParams` | `Promise<GroupMemberItem[]>` |
| `setGroupMemberInfo(params, operationID?)` | `UpdateMemberInfoParams` | `Promise<void>` |
| `getGroupMemberOwnerAndAdmin(groupID, operationID?)` | `string` | `Promise<GroupMemberItem[]>` |
| `kickGroupMember(params, operationID?)` | `OperateGroupParams` | `Promise<void>` |
| `changeGroupMemberMute(params, operationID?)` | `ChangeGroupMemberMuteParams` | `Promise<void>` |
| `changeGroupMute(params, operationID?)` | `ChangeGroupMuteParams` | `Promise<void>` |
| `transferGroupOwner(params, operationID?)` | `TransferGroupParams` | `Promise<void>` |
| `getGroupApplicationListAsRecipient(params?, operationID?)` | `GetGroupApplicationListAsRecipientParams?` | `Promise<GroupApplicationItem[]>` |
| `getGroupApplicationListAsApplicant(params?, operationID?)` | `GetGroupApplicationListAsApplicantParams?` | `Promise<GroupApplicationItem[]>` |
| `getGroupApplicationUnhandledCount(params, operationID?)` | `GetSelfApplicationUnhandledCountParams` | `Promise<number>` |
| `acceptGroupApplication(params, operationID?)` | `AccessGroupParams` | `Promise<void>` |
| `refuseGroupApplication(params, operationID?)` | `AccessGroupParams` | `Promise<void>` |
| `searchPublicGroups(keyword, joinStatus?, offset?, count?, operationID?)` | `string, number?, number?, number?` | `Promise<SearchPublicGroupsResult>` |
| `getGroupMemberListByJoinTimeFilter(params, operationID?)` | `GetGroupMemberByTimeParams` | `Promise<GroupMemberItem[]>` |

---

## Conversation Management

| Method | Params | Returns |
|--------|--------|---------|
| `getAllConversationList(operationID?)` | — | `Promise<ConversationItem[]>` |
| `getConversationListSplit(params, operationID?)` | `SplitConversationParams` | `Promise<ConversationItem[]>` |
| `getConversationListSplitApp(params, operationID?)` | `SplitConversationAppParams` | `Promise<ConversationItem[]>` |
| `getOneConversation(params, operationID?)` | `GetOneConversationParams` | `Promise<ConversationItem>` |
| `getMultipleConversation(conversationIDList, operationID?)` | `string[]` | `Promise<ConversationItem[]>` |
| `getConversationIDBySessionType(params, operationID?)` | `GetOneConversationParams` | `Promise<string>` |
| `getTotalUnreadMsgCount(operationID?)` | — | `Promise<number>` |
| `markConversationMessageAsRead(conversationID, operationID?)` | `string` | `Promise<void>` |
| `markAllConversationMessageAsRead(operationID?)` | — | `Promise<void>` |
| `pinMsg(conversationID, clientMsgID, operationID?)` | `string, string` | `Promise<void>` |
| `unpinMsg(conversationID, clientMsgID, operationID?)` | `string, string` | `Promise<void>` |
| `getPinnedMsgs(conversationID, operationID?)` | `string` | `Promise<PinnedMsgInfo[]>` |
| `getPinnedMessageList(params, operationID?)` | `GetPinnedMessageListParams` | `Promise<GetPinnedMessageListResult>` |
| `setConversation(params, operationID?)` | `SetConversationParams` | `Promise<void>` |
| `setConversationDraft(params, operationID?)` | `SetConversationDraftParams` | `Promise<void>` |
| `pinConversation(params, operationID?)` | `PinConversationParams` | `Promise<void>` |
| `setConversationRecvMessageOpt(params, operationID?)` | `SetConversationRecvOptParams` | `Promise<void>` |
| `setConversationPrivateChat(params, operationID?)` | `SetConversationPrivateParams` | `Promise<void>` |
| `setConversationBurnDuration(params, operationID?)` | `SetBurnDurationParams` | `Promise<void>` |
| `resetConversationGroupAtType(conversationID, operationID?)` | `string` | `Promise<void>` |
| `hideConversation(conversationID, operationID?)` | `string` | `Promise<void>` |
| `hideAllConversation(operationID?)` | — | `Promise<void>` |
| `clearConversationAndDeleteAllMsg(conversationID, operationID?)` | `string` | `Promise<void>` |
| `deleteConversationAndDeleteAllMsg(conversationID, operationID?)` | `string` | `Promise<void>` |

---

## Message Sending & Receiving

### Create Message (Local Only)

| Method | Params | Returns |
|--------|--------|---------|
| `createTextMessage(text, operationID?)` | `string` | `Promise<MessageItem>` |
| `createUrlTextMessage(text, urls, operationID?)` | `string, string[]` | `Promise<MessageItem>` |
| `createTextAtMessage(params, operationID?)` | `AtMsgParams` | `Promise<MessageItem>` |
| `createImageMessageFromFullPath(imagePath, operationID?)` | `string` | `Promise<MessageItem>` |
| `createImageMessageByURL(params, operationID?)` | `ImageMsgParams` | `Promise<MessageItem>` |
| `createVideoMessageFromFullPath(params, operationID?)` | `VideoMsgByPathParams` | `Promise<MessageItem>` |
| `createVideoMessageByURL(params, operationID?)` | `VideoMsgParams` | `Promise<MessageItem>` |
| `createSoundMessageFromFullPath(params, operationID?)` | `SoundMsgByPathParams` | `Promise<MessageItem>` |
| `createSoundMessageByURL(params, operationID?)` | `SoundMsgParams` | `Promise<MessageItem>` |
| `createFileMessageFromFullPath(params, operationID?)` | `FileMsgByPathParams` | `Promise<MessageItem>` |
| `createFileMessageByURL(params, operationID?)` | `FileMsgParams` | `Promise<MessageItem>` |
| `createLocationMessage(params, operationID?)` | `LocationMsgParams` | `Promise<MessageItem>` |
| `createQuoteMessage(params, operationID?)` | `QuoteMsgParams` | `Promise<MessageItem>` |
| `createCardMessage(params, operationID?)` | `CardElem` | `Promise<MessageItem>` |
| `createCustomMessage(params, operationID?)` | `CustomMsgParams` | `Promise<MessageItem>` |
| `createFaceMessage(params, operationID?)` | `FaceMessageParams` | `Promise<MessageItem>` |
| `createMergerMessage(params, operationID?)` | `MergerMsgParams` | `Promise<MessageItem>` |
| `createForwardMessage(params, operationID?)` | `MessageItem` | `Promise<MessageItem>` |
| `createLogMessage(content, level, operationID?)` | `string, string` | `Promise<MessageItem>` |
| `createStickerMessage(content, operationID?)` | `string` | `Promise<MessageItem>` |

### Send & Manage Messages

| Method | Params | Returns |
|--------|--------|---------|
| `sendMessage(params, operationID?)` | `SendMsgParams` | `Promise<MessageItem>` |
| `sendMessageNotOss(params, operationID?)` | `SendMsgParams` | `Promise<MessageItem>` |
| `revokeMessage(params, operationID?)` | `OperateMessageParams` | `Promise<void>` |
| `deleteMessage(params, operationID?)` | `OperateMessageParams` | `Promise<void>` |
| `deleteMessageFromLocalStorage(params, operationID?)` | `OperateMessageParams` | `Promise<void>` |
| `deleteAllMsgFromLocal(operationID?)` | — | `Promise<void>` |
| `deleteAllMsgFromLocalAndSvr(operationID?)` | — | `Promise<void>` |

### Message Search & History

| Method | Params | Returns |
|--------|--------|---------|
| `searchLocalMessages(params, operationID?)` | `SearchLocalParams` | `Promise<SearchMessageResult>` |
| `getAdvancedHistoryMessageList(params, operationID?)` | `GetAdvancedHistoryMsgParams` | `Promise<AdvancedGetMessageResult>` |
| `getAdvancedHistoryMessageListReverse(params, operationID?)` | `GetAdvancedHistoryMsgParams` | `Promise<AdvancedGetMessageResult>` |
| `getAdvancedHistoryMessageListApp(params, operationID?)` | `GetAdvancedHistoryMsgAppParams` | `Promise<AdvancedGetMessageResult>` |
| `getAdvancedHistoryMessageListReverseApp(params, operationID?)` | `GetAdvancedHistoryMsgAppParams` | `Promise<AdvancedGetMessageResult>` |
| `findMessageList(params, operationID?)` | `FindMessageParams[]` | `Promise<SearchMessageResult>` |
| `insertGroupMessageToLocalStorage(params, operationID?)` | `InsertGroupMsgParams` | `Promise<void>` |
| `insertSingleMessageToLocalStorage(params, operationID?)` | `InsertSingleMsgParams` | `Promise<void>` |
| `setMessageLocalEx(params, operationID?)` | `SetMessageLocalExParams` | `Promise<void>` |

### Input States & Typing

| Method | Params | Returns |
|--------|--------|---------|
| `typingStatusUpdate(params, operationID?)` | `TypingUpdateParams` | `Promise<void>` |
| `changeInputStates(params, operationID?)` | `ChangeInputStatesParams` | `Promise<void>` |
| `getInputStates(params, operationID?)` | `GetInputStatesParams` | `Promise<number[]>` |

---

## Upload & Utility

| Method | Params | Returns |
|--------|--------|---------|
| `uploadFile(params, operationID?)` | `UploadFileParams` | `Promise<{url: string}>` |
| `uploadLogs(params, operationID?)` | `UploadLogsParams` | `Promise<void>` |
| `logs(params, operationID?)` | `LogsParams` | `Promise<void>` |
| `addUserCommand(type, uuid, value, operationID?)` | `number, string, string` | `Promise<void>` |
| `deleteUserCommand(type, uuid, operationID?)` | `number, string` | `Promise<void>` |
| `getAllUserCommands(type, operationID?)` | `number` | `Promise<void>` |

---

## Events (~45 Total)

### Connection Events

- `OnConnecting` — Attempting to connect
- `OnConnectSuccess` — Connected successfully
- `OnConnectFailed({errCode, errMsg})` — Connection failed
- `OnKickedOffline` — Kicked off (other device logged in)
- `OnUserTokenExpired` — JWT token expired; must re-login
- `OnUserTokenInvalid` — JWT token invalid; must re-login

### User Events

- `OnSelfInfoUpdated([SelfUserInfo])` — Self info changed
- `OnUserStatusChanged([UserOnlineState])` — User(s) online/offline status changed

### Message Events

- `OnRecvNewMessage(MessageItem)` — Single message received (chat types: 101–162)
- `OnRecvNewMessages(MessageItem[])` — Batch messages received
- `OnRecvOfflineNewMessage(MessageItem)` — Offline message(s) delivered
- `OnRecvOnlineOnlyMessage(MessageItem)` — Online-only message received
- `OnRecvOfflineNewMessages(MessageItem[])` — Batch offline messages
- `OnMsgDeleted(RevokedInfo)` — Message deleted from server
- `OnRecvC2CReadReceipt(ReceiptInfo[])` — Read receipts received
- `OnNewRecvMessageRevoked(RevokedInfo)` — Message revoked
- `OnRecvMessagePinned(MessagePinned)` — Message pinned/unpinned

### Conversation Events

- `OnConversationChanged(ConversationItem[])` — Conversation(s) properties changed
- `OnNewConversation(ConversationItem)` — New conversation started
- `OnTotalUnreadMessageCountChanged(number)` — Unread count changed
- `OnInputStatusChanged({sessionType, fromUserID, inputStates[]})` — User typing status changed
- `OnSyncServerStart(boolean)` — Server sync started
- `OnSyncServerProgress(number)` — Sync progress (%)
- `OnSyncServerFinish` — Sync completed
- `OnSyncServerFailed` — Sync failed

### Friend Events

- `OnFriendAdded(FriendUserItem)` — Friend added
- `OnFriendDeleted(string)` — Friend deleted (userID)
- `OnBlackAdded(BlackUserItem)` — User added to block list
- `OnBlackDeleted(string)` — User removed from block list
- `OnFriendApplicationAdded(FriendApplicationItem)` — Friend request received
- `OnFriendApplicationAccepted(FriendApplicationItem)` — Friend request accepted
- `OnFriendApplicationRejected(FriendApplicationItem)` — Friend request rejected
- `OnFriendApplicationDeleted(string)` — Friend request deleted (userID)
- `OnFriendInfoChanged(FriendUserItem[])` — Friend info changed (remark, etc.)

### Group Events

- `OnJoinedGroupAdded(GroupItem)` — User joined group
- `OnJoinedGroupDeleted(string)` — User left/removed from group (groupID)
- `OnGroupInfoChanged(GroupItem)` — Group info changed (name, avatar, etc.)
- `OnGroupMemberAdded(GroupMemberItem[])` — Member(s) added to group
- `OnGroupMemberDeleted(GroupMemberItem[])` — Member(s) removed from group
- `OnGroupMemberInfoChanged(GroupMemberItem[])` — Member info changed (role, mute status)
- `OnGroupApplicationAdded(GroupApplicationItem)` — Join request received
- `OnGroupApplicationAccepted(GroupApplicationItem)` — Join request accepted
- `OnGroupApplicationRejected(GroupApplicationItem)` — Join request rejected
- `OnGroupApplicationDeleted(string)` — Join request deleted (applicationID)
- `OnGroupDismissed(string)` — Group dissolved (groupID)

### Upload & Misc Events

- `SendMessageProgress({progress: number, message: string})` — Message upload progress
- `UploadOnProgress({progress: number, path: string})` — File upload progress
- `UploadComplete` — File upload complete
- `OnRecvCustomBusinessMessage(...)` — Custom business notification

---

## Key Enums

**MessageType** (see `docs/system-architecture.md` for complete table)

```typescript
export enum MessageType {
  TextMessage = 101,
  PictureMessage = 102,
  VoiceMessage = 103,
  VideoMessage = 104,
  FileMessage = 105,
  AtTextMessage = 106,
  MergeMessage = 107,
  CardMessage = 108,
  LocationMessage = 109,
  CustomMessage = 110,
  // ... + 50 more values (1200–2200 for system notifications)
}
```

**Other Enums**

- `LoginStatus` (Logout=1, Logging=2, Logged=3)
- `OnlineState` (Online=1, Offline=0)
- `GroupMemberRole` (Normal=20, Admin=60, Owner=100)
- `GroupType` (Group=2)
- `GroupVisibility` (Private=0, Public=1)
- `MessageStatus` (Sending=1, Succeed=2, Failed=3)
- `MessageReceiveOptType` (Normal=0, NotReceive=1, NotNotify=2)
- `SessionType` (Single=1, Group=3, WorkingGroup=3, Notification=4)
- And 14 more...

See `src/types/enum.ts` for all 22 enums.

---

## Data Shapes (Key Types)

**MessageItem** — Complete message envelope
```typescript
{
  clientMsgID: string;
  serverMsgID: string;
  createTime: number;      // epoch ms
  sendTime: number;        // epoch ms
  contentType: MessageType;
  from: string;            // sender userID
  to: string;              // recipient userID (empty for group)
  groupID: string;         // group ID (empty for 1-to-1)
  status: MessageStatus;
  ex: string;              // app-defined extra data
  
  // One of these is populated per contentType:
  textElem?: TextElem;
  pictureElem?: PictureElem;
  soundElem?: SoundElem;
  videoElem?: VideoElem;
  fileElem?: FileElem;
  atTextElem?: AtTextElem;
  quoteElem?: QuoteElem;
  // ... and ~15 more element types
}
```

**ConversationItem** — Conversation state
```typescript
{
  conversationID: string;
  conversationType: SessionType;
  userID?: string;         // peer userID (if 1-to-1)
  groupID?: string;        // group ID (if group)
  showName: string;        // display name
  faceURL: string;         // avatar URL
  recvMsgOpt: MessageReceiveOptType;
  unreadCount: number;
  lastMessage?: MessageItem;
  lastMsgSendTime: number;
  draftText: string;
  draftTextTime: number;
  isPinned: boolean;
  isPrivateChat: boolean;
  burnDuration: number;    // seconds until auto-delete (0 = off)
  isNotInGroup: boolean;
  ex: string;
}
```

**GroupItem** — Group metadata
```typescript
{
  groupID: string;
  groupName: string;
  notification: string;
  introduction: string;
  faceURL: string;
  owner: string;           // owner userID
  createTime: number;
  memberCount: number;
  ex: string;
  status: GroupStatus;
  creatorUserID: string;
  groupType: GroupType;
  needVerification: GroupVerificationType;
  lookMemberCount: boolean;
}
```

**GroupMemberItem**
```typescript
{
  groupID: string;
  userID: string;
  displayName: string;
  faceURL: string;
  roleLevel: GroupMemberRole;
  joinTime: number;
  muteEndTime: number;
  ex: string;
}
```

See `src/types/entity.ts` for 20+ more data shapes.

---

## Error Handling

All API errors throw `OpenIMApiError`:

```typescript
try {
  await OpenIMSDK.login({ userID: 'u1', token: 'bad' });
} catch (error) {
  if (error instanceof OpenIMApiError) {
    console.error(`[${error.operationID}] Error ${error.code}: ${error.message}`);
  }
}
```

Common error codes:
- **200** — Success
- **1000** — Invalid params
- **1001** — User not found
- **1002** — Token invalid/expired
- **1100** — Friend not found
- **1101** — Blacklist error
- **1200** — Group not found
- **1201** — Member not in group
- **1202** — Permission denied

See OpenIM server docs for full error code reference.

---

## Installation & Integration

**See `docs/deployment-guide.md` for detailed instructions.**

Quick:
```sh
npm install @droppii/openim-rn-client-sdk
cd ios && pod install && cd ..
```

For Expo:
```sh
npx expo prebuild
```

---

## License

Apache 2.0 — see [LICENSE](../LICENSE).
