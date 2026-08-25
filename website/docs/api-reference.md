---
id: api-reference
title: API Reference
sidebar_position: 5
---


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
| `initSDK(options, operationID?)` | [`InitOptions`](#initoptions) | `Promise<void>` | Initialize SDK; must be first call |
| `login(params, operationID?)` | [`LoginParams`](#loginparams) | `Promise<void>` | Login with userID + JWT token |
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
| `addFriend(params, operationID?)` | [`AddFriendParams`](#addfriendparams) | `Promise<void>` |
| `deleteFriend(userID, operationID?)` | `string` | `Promise<void>` |
| `checkFriend(userIDList, operationID?)` | `string[]` | `Promise<FriendshipInfo[]>` |
| `acceptFriendApplication(params, operationID?)` | [`AccessFriendParams`](#accessfriendparams) | `Promise<void>` |
| `refuseFriendApplication(params, operationID?)` | [`AccessFriendParams`](#accessfriendparams) | `Promise<void>` |
| `getFriendList(filterBlack, operationID?)` | `boolean` | `Promise<FriendUserItem[]>` |
| `getFriendListPage(params, operationID?)` | `OffsetParams & {filterBlack?}` | `Promise<FriendUserItem[]>` |
| `getSpecifiedFriendsInfo(params, operationID?)` | [`GetSpecifiedFriendsParams`](#getspecifiedfriendsparams) | `Promise<FriendUserItem[]>` |
| `updateFriends(params, operationID?)` | [`UpdateFriendsParams`](#updatefriendsparams) | `Promise<void>` |
| `searchFriends(params, operationID?)` | [`SearchFriendParams`](#searchfriendparams) | `Promise<SearchedFriendsInfo[]>` |
| `setFriendRemark(params, operationID?)` | [`RemarkFriendParams`](#remarkfriendparams) | `Promise<void>` |
| `addBlack(params, operationID?)` | [`AddBlackParams`](#addblackparams) | `Promise<void>` |
| `removeBlack(userID, operationID?)` | `string` | `Promise<void>` |
| `getBlackList(operationID?)` | — | `Promise<BlackUserItem[]>` |
| `getFriendApplicationListAsApplicant(params?, operationID?)` | `GetFriendApplicationListAsApplicantParams?` | `Promise<FriendApplicationItem[]>` |
| `getFriendApplicationListAsRecipient(params?, operationID?)` | `GetFriendApplicationListAsRecipientParams?` | `Promise<FriendApplicationItem[]>` |
| `getFriendApplicationUnhandledCount(params, operationID?)` | [`GetSelfApplicationUnhandledCountParams`](#getselfapplicationunhandledcountparams) | `Promise<number>` |

---

## Group Management

| Method | Params | Returns |
|--------|--------|---------|
| `createGroup(params, operationID?)` | [`CreateGroupParams`](#creategroupparams) | `Promise<GroupItem>` |
| `joinGroup(params, operationID?)` | [`JoinGroupParams`](#joingroupparams) | `Promise<void>` |
| `inviteUserToGroup(params, operationID?)` | [`OperateGroupParams`](#operategroupparams) | `Promise<void>` |
| `getJoinedGroupList(operationID?)` | — | `Promise<GroupItem[]>` |
| `getJoinedGroupListPage(params, operationID?)` | [`OffsetParams`](#offsetparams) | `Promise<GroupItem[]>` |
| `searchGroups(params, operationID?)` | [`SearchGroupParams`](#searchgroupparams) | `Promise<GroupItem[]>` |
| `getSpecifiedGroupsInfo(groupIDs, operationID?)` | `string[]` | `Promise<GroupItem[]>` |
| `setGroupInfo(params, operationID?)` | [`SetGroupInfoParams`](#setgroupinfoparams) | `Promise<void>` |
| `dismissGroup(groupID, operationID?)` | `string` | `Promise<void>` |
| `quitGroup(groupID, operationID?)` | `string` | `Promise<void>` |
| `isJoinGroup(groupID, operationID?)` | `string` | `Promise<boolean>` |
| `getGroupMemberList(params, operationID?)` | [`GetGroupMemberParams`](#getgroupmemberparams) | `Promise<GroupMemberItem[]>` |
| `getSpecifiedGroupMembersInfo(params, operationID?)` | [`GetGroupMembersInfoParams`](#getgroupmembersinfoparams) | `Promise<GroupMemberItem[]>` |
| `getUsersInGroup(params, operationID?)` | [`GetGroupMembersInfoParams`](#getgroupmembersinfoparams) | `Promise<GroupMemberItem[]>` |
| `searchGroupMembers(params, operationID?)` | [`SearchGroupMemberParams`](#searchgroupmemberparams) | `Promise<GroupMemberItem[]>` |
| `setGroupMemberInfo(params, operationID?)` | [`UpdateMemberInfoParams`](#updatememberinfoparams) | `Promise<void>` |
| `getGroupMemberOwnerAndAdmin(groupID, operationID?)` | `string` | `Promise<GroupMemberItem[]>` |
| `kickGroupMember(params, operationID?)` | [`OperateGroupParams`](#operategroupparams) | `Promise<void>` |
| `changeGroupMemberMute(params, operationID?)` | [`ChangeGroupMemberMuteParams`](#changegroupmembermuteparams) | `Promise<void>` |
| `changeGroupMute(params, operationID?)` | [`ChangeGroupMuteParams`](#changegroupmuteparams) | `Promise<void>` |
| `transferGroupOwner(params, operationID?)` | [`TransferGroupParams`](#transfergroupparams) | `Promise<void>` |
| `getGroupApplicationListAsRecipient(params?, operationID?)` | `GetGroupApplicationListAsRecipientParams?` | `Promise<GroupApplicationItem[]>` |
| `getGroupApplicationListAsApplicant(params?, operationID?)` | `GetGroupApplicationListAsApplicantParams?` | `Promise<GroupApplicationItem[]>` |
| `getGroupApplicationUnhandledCount(params, operationID?)` | [`GetSelfApplicationUnhandledCountParams`](#getselfapplicationunhandledcountparams) | `Promise<number>` |
| `acceptGroupApplication(params, operationID?)` | [`AccessGroupParams`](#accessgroupparams) | `Promise<void>` |
| `refuseGroupApplication(params, operationID?)` | [`AccessGroupParams`](#accessgroupparams) | `Promise<void>` |
| `searchPublicGroups(keyword, joinStatus?, offset?, count?, operationID?)` | `string, number?, number?, number?` | `Promise<SearchPublicGroupsResult>` |
| `getGroupMemberListByJoinTimeFilter(params, operationID?)` | [`GetGroupMemberByTimeParams`](#getgroupmemberbytimeparams) | `Promise<GroupMemberItem[]>` |

---

## Conversation Management

| Method | Params | Returns |
|--------|--------|---------|
| `getAllConversationList(operationID?)` | — | `Promise<ConversationItem[]>` |
| `getConversationListSplit(params, operationID?)` | [`SplitConversationParams`](#splitconversationparams) | `Promise<ConversationItem[]>` |
| `getConversationListSplitApp(params, operationID?)` | [`SplitConversationAppParams`](#splitconversationappparams) | `Promise<ConversationItem[]>` |
| `getOneConversation(params, operationID?)` | [`GetOneConversationParams`](#getoneconversationparams) | `Promise<ConversationItem>` |
| `getMultipleConversation(conversationIDList, operationID?)` | `string[]` | `Promise<ConversationItem[]>` |
| `getConversationIDBySessionType(params, operationID?)` | [`GetOneConversationParams`](#getoneconversationparams) | `Promise<string>` |
| `getTotalUnreadMsgCount(operationID?)` | — | `Promise<number>` |
| `markConversationMessageAsRead(conversationID, operationID?)` | `string` | `Promise<void>` |
| `markAllConversationMessageAsRead(operationID?)` | — | `Promise<void>` |
| `pinMsg(conversationID, clientMsgID, operationID?)` | `string, string` | `Promise<void>` |
| `unpinMsg(conversationID, clientMsgID, operationID?)` | `string, string` | `Promise<void>` |
| `getPinnedMsgs(conversationID, operationID?)` | `string` | `Promise<PinnedMsgInfo[]>` |
| `getPinnedMessageList(params, operationID?)` | [`GetPinnedMessageListParams`](#getpinnedmessagelistparams) | `Promise<GetPinnedMessageListResult>` |
| `setConversation(params, operationID?)` | [`SetConversationParams`](#setconversationparams) | `Promise<void>` |
| `setConversationDraft(params, operationID?)` | [`SetConversationDraftParams`](#setconversationdraftparams) | `Promise<void>` |
| `pinConversation(params, operationID?)` | [`PinConversationParams`](#pinconversationparams) | `Promise<void>` |
| `setConversationRecvMessageOpt(params, operationID?)` | [`SetConversationRecvOptParams`](#setconversationrecvoptparams) | `Promise<void>` |
| `setConversationPrivateChat(params, operationID?)` | [`SetConversationPrivateParams`](#setconversationprivateparams) | `Promise<void>` |
| `setConversationBurnDuration(params, operationID?)` | [`SetBurnDurationParams`](#setburndurationparams) | `Promise<void>` |
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
| `createTextAtMessage(params, operationID?)` | [`AtMsgParams`](#atmsgparams) | `Promise<MessageItem>` |
| `createImageMessageFromFullPath(imagePath, operationID?)` | `string` | `Promise<MessageItem>` |
| `createImageMessageByURL(params, operationID?)` | [`ImageMsgParams`](#imagemsgparams) | `Promise<MessageItem>` |
| `createVideoMessageFromFullPath(params, operationID?)` | [`VideoMsgByPathParams`](#videomsgbypathparams) | `Promise<MessageItem>` |
| `createVideoMessageByURL(params, operationID?)` | [`VideoMsgParams`](#videomsgparams) | `Promise<MessageItem>` |
| `createSoundMessageFromFullPath(params, operationID?)` | [`SoundMsgByPathParams`](#soundmsgbypathparams) | `Promise<MessageItem>` |
| `createSoundMessageByURL(params, operationID?)` | [`SoundMsgParams`](#soundmsgparams) | `Promise<MessageItem>` |
| `createFileMessageFromFullPath(params, operationID?)` | [`FileMsgByPathParams`](#filemsgbypathparams) | `Promise<MessageItem>` |
| `createFileMessageByURL(params, operationID?)` | [`FileMsgParams`](#filemsgparams) | `Promise<MessageItem>` |
| `createLocationMessage(params, operationID?)` | [`LocationMsgParams`](#locationmsgparams) | `Promise<MessageItem>` |
| `createQuoteMessage(params, operationID?)` | [`QuoteMsgParams`](#quotemsgparams) | `Promise<MessageItem>` |
| `createCardMessage(params, operationID?)` | `CardElem` | `Promise<MessageItem>` |
| `createCustomMessage(params, operationID?)` | [`CustomMsgParams`](#custommsgparams) | `Promise<MessageItem>` |
| `createFaceMessage(params, operationID?)` | [`FaceMessageParams`](#facemessageparams) | `Promise<MessageItem>` |
| `createMergerMessage(params, operationID?)` | [`MergerMsgParams`](#mergermsgparams) | `Promise<MessageItem>` |
| `createForwardMessage(params, operationID?)` | `MessageItem` | `Promise<MessageItem>` |
| `createLogMessage(content, level, operationID?)` | `string, string` | `Promise<MessageItem>` |
| `createStickerMessage(content, operationID?)` | `string` | `Promise<MessageItem>` |

### Send & Manage Messages

| Method | Params | Returns |
|--------|--------|---------|
| `sendMessage(params, operationID?)` | [`SendMsgParams`](#sendmsgparams) | `Promise<MessageItem>` |
| `sendMessageNotOss(params, operationID?)` | [`SendMsgParams`](#sendmsgparams) | `Promise<MessageItem>` |
| `revokeMessage(params, operationID?)` | [`OperateMessageParams`](#operatemessageparams) | `Promise<void>` |
| `deleteMessage(params, operationID?)` | [`OperateMessageParams`](#operatemessageparams) | `Promise<void>` |
| `deleteMessageFromLocalStorage(params, operationID?)` | [`OperateMessageParams`](#operatemessageparams) | `Promise<void>` |
| `deleteAllMsgFromLocal(operationID?)` | — | `Promise<void>` |
| `deleteAllMsgFromLocalAndSvr(operationID?)` | — | `Promise<void>` |

### Message Search & History

| Method | Params | Returns |
|--------|--------|---------|
| `searchLocalMessages(params, operationID?)` | [`SearchLocalParams`](#searchlocalparams) | `Promise<SearchMessageResult>` |
| `getAdvancedHistoryMessageList(params, operationID?)` | [`GetAdvancedHistoryMsgParams`](#getadvancedhistorymsgparams) | `Promise<AdvancedGetMessageResult>` |
| `getAdvancedHistoryMessageListReverse(params, operationID?)` | [`GetAdvancedHistoryMsgParams`](#getadvancedhistorymsgparams) | `Promise<AdvancedGetMessageResult>` |
| `getAdvancedHistoryMessageListApp(params, operationID?)` | [`GetAdvancedHistoryMsgAppParams`](#getadvancedhistorymsgappparams) | `Promise<AdvancedGetMessageResult>` |
| `getAdvancedHistoryMessageListReverseApp(params, operationID?)` | [`GetAdvancedHistoryMsgAppParams`](#getadvancedhistorymsgappparams) | `Promise<AdvancedGetMessageResult>` |
| `findMessageList(params, operationID?)` | `FindMessageParams[]` | `Promise<SearchMessageResult>` |
| `insertGroupMessageToLocalStorage(params, operationID?)` | [`InsertGroupMsgParams`](#insertgroupmsgparams) | `Promise<void>` |
| `insertSingleMessageToLocalStorage(params, operationID?)` | [`InsertSingleMsgParams`](#insertsinglemsgparams) | `Promise<void>` |
| `setMessageLocalEx(params, operationID?)` | [`SetMessageLocalExParams`](#setmessagelocalexparams) | `Promise<void>` |

### Input States & Typing

| Method | Params | Returns |
|--------|--------|---------|
| `typingStatusUpdate(params, operationID?)` | [`TypingUpdateParams`](#typingupdateparams) | `Promise<void>` |
| `changeInputStates(params, operationID?)` | [`ChangeInputStatesParams`](#changeinputstatesparams) | `Promise<void>` |
| `getInputStates(params, operationID?)` | [`GetInputStatesParams`](#getinputstatesparams) | `Promise<number[]>` |

---

## Upload & Utility

| Method | Params | Returns |
|--------|--------|---------|
| `uploadFile(params, operationID?)` | [`UploadFileParams`](#uploadfileparams) | `Promise<{url: string}>` |
| `uploadLogs(params, operationID?)` | [`UploadLogsParams`](#uploadlogsparams) | `Promise<void>` |
| `logs(params, operationID?)` | [`LogsParams`](#logsparams) | `Promise<void>` |
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

## Params Reference

Every `*Params` type referenced in the method tables above, sourced directly from `src/types/params.ts`.

### Auth & User

#### InitOptions
```typescript
{
  apiAddr: string;
  wsAddr: string;
  dataDir: string;
  logFilePath: string;
  logLevel: LogLevel;
  isLogStandardOutput: boolean;
}
```

#### LoginParams
```typescript
{
  userID: string;
  token: string;
}
```

#### OffsetParams
```typescript
{
  offset: number;
  count: number;
}
```

### Conversation

#### SplitConversationParams
```typescript
{
  offset: number;
  count: number;
}
```

#### SplitConversationAppParams
```typescript
{
  offset: number;
  count: number;
  applicationType: string;
  chatCategory?: string;
}
```

#### GetOneConversationParams
```typescript
{
  sourceID: string;
  sessionType: SessionType;
}
```

#### SetConversationParams
```typescript
{
  conversationID: string;
  recvMsgOpt?: MessageReceiveOptType;
  groupAtType?: GroupAtType;
  burnDuration?: number;
  msgDestructTime?: number;
  isPinned?: boolean;
  isPrivateChat?: boolean;
  isMsgDestruct?: boolean;
  ex?: string;
}
```

#### SetConversationDraftParams
```typescript
{
  conversationID: string;
  draftText: string;
}
```

#### PinConversationParams
```typescript
{
  conversationID: string;
  isPinned: boolean;
}
```

#### SetConversationRecvOptParams
```typescript
{
  conversationID: string;
  opt: MessageReceiveOptType;
}
```

#### SetConversationPrivateParams
```typescript
{
  conversationID: string;
  isPrivate: boolean;
}
```

#### SetBurnDurationParams
```typescript
{
  conversationID: string;
  burnDuration: number;
}
```

#### GetPinnedMessageListParams
```typescript
{
  conversationID: string;
  offset: number;
  pageSize: number;
}
```

### Friend

#### GetSpecifiedFriendsParams
```typescript
{
  userIDList: string[];
  filterBlack?: boolean;
}
```

#### UpdateFriendsParams
```typescript
{
  friendUserIDs: string[];
  isPinned?: boolean;
  remark?: boolean;
  ex?: boolean;
}
```

#### AccessFriendParams
```typescript
{
  toUserID: string;
  handleMsg: string;
}
```

#### AddBlackParams
```typescript
{
  toUserID: string;
  ex?: string;
}
```

#### AddFriendParams
```typescript
{
  toUserID: string;
  reqMsg: string;
}
```

#### GetFriendApplicationListAsRecipientParams
```typescript
{
  handleResults: number[];
  offset: number;
  count: number;
}
```

#### GetFriendApplicationListAsApplicantParams
```typescript
{
  offset: number;
  count: number;
}
```

#### GetSelfApplicationUnhandledCountParams
```typescript
{
  time: number;
}
```

#### SearchFriendParams
```typescript
{
  keywordList: string[];
  isSearchUserID: boolean;
  isSearchNickname: boolean;
  isSearchRemark: boolean;
}
```

#### RemarkFriendParams
```typescript
{
  friendUserIDs: string;
  remark: string;
}
```

### Group

#### CreateGroupParams
```typescript
{
  memberUserIDs: string[];
  groupInfo: Partial<GroupItem>;
  adminUserIDs?: string[];
  ownerUserID?: string;
}
```

#### JoinGroupParams
```typescript
{
  groupID: string;
  reqMsg: string;
  joinSource: GroupJoinSource;
  ex?: string;
}
```

#### OperateGroupParams
```typescript
{
  groupID: string;
  reason: string;
  userIDList: string[];
}
```

#### SearchGroupParams
```typescript
{
  keywordList: string[];
  isSearchGroupID: boolean;
  isSearchGroupName: boolean;
}
```

#### SetGroupInfoParams
```typescript
Partial<GroupItem> & { groupID: string }
```

#### GetGroupApplicationListAsRecipientParams
```typescript
{
  groupIDs: string[];
  handleResults: number[];
  offset: number;
  count: number;
}
```

#### GetGroupApplicationListAsApplicantParams
```typescript
{
  groupIDs: string[];
  handleResults: number[];
  offset: number;
  count: number;
}
```

#### AccessGroupParams
```typescript
{
  groupID: string;
  fromUserID: string;
  handleMsg: string;
}
```

#### GetGroupMemberParams
```typescript
{
  groupID: string;
  filter: GroupMemberFilter;
  offset: number;
  count: number;
}
```

#### GetGroupMembersInfoParams
```typescript
{
  groupID: string;
  userIDList: string[];
}
```

#### SearchGroupMemberParams
```typescript
{
  groupID: string;
  keywordList: string[];
  isSearchUserID: boolean;
  isSearchMemberNickname: boolean;
  offset: number;
  count: number;
}
```

#### UpdateMemberInfoParams
```typescript
{
  groupID: string;
  userID: string;
  nickname?: string;
  faceURL?: string;
  roleLevel?: GroupMemberRole;
  ex?: string;
}
```

#### GetGroupMemberByTimeParams
```typescript
{
  groupID: string;
  filterUserIDList: string[];
  offset: number;
  count: number;
  joinTimeBegin: number;
  joinTimeEnd: number;
}
```

#### ChangeGroupMemberMuteParams
```typescript
{
  groupID: string;
  userID: string;
  mutedSeconds: number;
}
```

#### ChangeGroupMuteParams
```typescript
{
  groupID: string;
  isMute: boolean;
}
```

#### TransferGroupParams
```typescript
{
  groupID: string;
  newOwnerUserID: string;
}
```

### Message Creation

#### SoundMsgByPathParams
```typescript
{
  soundPath: string;
  duration: number;
}
```

#### VideoMsgByPathParams
```typescript
{
  videoPath: string;
  videoType: string;
  duration: number;
  snapshotPath: string;
}
```

#### FileMsgByPathParams
```typescript
{
  filePath: string;
  fileName: string;
}
```

#### AtMsgParams
```typescript
{
  text: string;
  atUserIDList: string[];
  atUsersInfo?: AtUsersInfoItem[];
  message?: MessageItem;
}
```

#### ImageMsgParams
```typescript
{
  sourcePicture: PicBaseInfo;
  bigPicture: PicBaseInfo;
  snapshotPicture: PicBaseInfo;
  sourcePath: string;
}
```

#### SoundMsgParams
```typescript
{
  uuid: string;
  soundPath: string;
  sourceUrl: string;
  dataSize: number;
  duration: number;
  soundType?: string;
}
```

#### VideoMsgParams
```typescript
{
  videoPath: string;
  duration: number;
  videoType: string;
  snapshotPath: string;
  videoUUID: string;
  videoUrl: string;
  videoSize: number;
  snapshotUUID: string;
  snapshotSize: number;
  snapshotUrl: string;
  snapshotWidth: number;
  snapshotHeight: number;
  snapShotType?: string;
}
```

#### FileMsgParams
```typescript
{
  filePath: string;
  fileName: string;
  uuid: string;
  sourceUrl: string;
  fileSize: number;
  fileType?: string;
}
```

#### MergerMsgParams
```typescript
{
  messageList: MessageItem[];
  title: string;
  summaryList: string[];
}
```

#### LocationMsgParams
```typescript
{
  description: string;
  longitude: number;
  latitude: number;
}
```

#### QuoteMsgParams
```typescript
{
  text: string;
  message: MessageItem;
}
```

#### CustomMsgParams
```typescript
{
  data: string;
  extension: string;
  description: string;
}
```

#### FaceMessageParams
```typescript
{
  index: number;
  data: string;
}
```

### Message Send & Query

#### SendMsgParams
```typescript
{
  recvID: string;
  groupID: string;
  offlinePushInfo?: OfflinePush;
  message: MessageItem;
  isOnlineOnly?: boolean;
}
```

#### TypingUpdateParams
```typescript
{
  recvID: string;
  msgTip: string;
}
```

#### ChangeInputStatesParams
```typescript
{
  conversationID: string;
  focus: boolean;
}
```

#### GetInputStatesParams
```typescript
{
  conversationID: string;
  userID: string;
}
```

#### OperateMessageParams
```typescript
{
  conversationID: string;
  clientMsgID: string;
}
```

#### SearchLocalParams
```typescript
{
  conversationID: string;
  keywordList: string[];
  keywordListMatchType?: number;
  senderUserIDList?: string[];
  messageTypeList?: MessageType[];
  searchTimePosition?: number;
  searchTimePeriod?: number;
  pageIndex?: number;
  count?: number;
}
```

#### GetAdvancedHistoryMsgParams
```typescript
{
  viewType: ViewType;
  count: number;
  startClientMsgID: string;
  conversationID: string;
}
```

#### GetAdvancedHistoryMsgAppParams
```typescript
GetAdvancedHistoryMsgParams & {
  applicationType: string;
  chatCategory?: string;
}
```

#### FindMessageParams
```typescript
{
  conversationID: string;
  clientMsgIDList: string[];
}
```

#### InsertGroupMsgParams
```typescript
{
  message: MessageItem;
  groupID: string;
  sendID: string;
}
```

#### InsertSingleMsgParams
```typescript
{
  message: MessageItem;
  recvID: string;
  sendID: string;
}
```

#### SetMessageLocalExParams
```typescript
{
  conversationID: string;
  clientMsgID: string;
  localEx: string;
}
```

### Upload & Logs

#### UploadFileParams
```typescript
{
  name: string;
  contentType: string;
  uuid: string;
  cause?: string;
  filepath: string;
}
```

#### UploadLogsParams
```typescript
{
  line: number;
  ex?: string;
}
```

#### LogsParams
```typescript
{
  logLevel: number;
  file: string;
  line: number;
  msgs: string;
  err: string;
  keyAndValue: string[];
}
```

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

Apache 2.0 — see [LICENSE](https://github.com/droppii/open-im-sdk-reactnative/blob/main/LICENSE).
