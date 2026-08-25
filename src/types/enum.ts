export enum MessageReceiveOptType {
  Normal = 0,
  NotReceive = 1,
  NotNotify = 2,
}
export enum AllowType {
  Allowed = 0,
  NotAllowed = 1,
}
export enum GroupType {
  Group = 2,
  WorkingGroup = 2,
}
export enum GroupJoinSource {
  Invitation = 2,
  Search = 3,
  QrCode = 4,
}
export enum GroupMemberRole {
  Normal = 20,
  Admin = 60,
  Owner = 100,
}
export enum GroupVerificationType {
  ApplyNeedInviteNot = 0,
  AllNeed = 1,
  AllNot = 2,
}
export enum MessageStatus {
  Sending = 1,
  Succeed = 2,
  Failed = 3,
}
export enum Platform {
  iOS = 1,
  Android = 2,
  Windows = 3,
  MacOSX = 4,
  Web = 5,
  Linux = 7,
  AndroidPad = 8,
  iPad = 9,
}
export enum LogLevel {
  Debug = 5,
  Info = 4,
  Warn = 3,
  Error = 2,
  Fatal = 1,
  Panic = 0,
}
export enum ApplicationHandleResult {
  Unprocessed = 0,
  Agree = 1,
  Reject = -1,
}
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
  RevokedMessage = 111,
  TypingMessage = 113,
  QuoteMessage = 114,
  FaceMessage = 115,
  AdvancedTextMessage = 117,
  MarkdownTextMessage = 118,
  CustomNotTriggerConversation = 119,
  CustomOnlineOnlyMessage = 120,
  ReactionMessageModifier = 121,
  ReactionMessageDeleter = 122,
  UrlTextMessage = 160,
  LogTextMessage = 161,
  StickerMessage = 162,

  FriendAdded = 1201,
  FriendApplicationRejected = 1202,
  FriendApplicationReceived = 1203,
  FriendAddSuccess = 1204,
  FriendDeleted = 1205,
  FriendRemarkSet = 1206,
  BlackAdded = 1207,
  BlackDeleted = 1208,
  FriendInfoUpdated = 1209,
  FriendsInfoUpdate = 1210,

  ConversationChanged = 1300,
  UserInfoUpdated = 1303,
  UserStatusChanged = 1304,
  UserCommandAdd = 1305,
  UserCommandDelete = 1306,
  UserCommandUpdate = 1307,
  UserSubscribeOnlineStatus = 1308,

  OANotification = 1400,

  GroupCreated = 1501,
  GroupInfoUpdated = 1502,
  JoinGroupApplication = 1503,
  MemberQuit = 1504,
  GroupApplicationAccepted = 1505,
  GroupApplicationRejected = 1506,
  GroupOwnerTransferred = 1507,
  MemberKicked = 1508,
  MemberInvited = 1509,
  MemberEnter = 1510,
  GroupDismissed = 1511,
  GroupMemberMuted = 1512,
  GroupMemberCancelMuted = 1513,
  GroupMuted = 1514,
  GroupCancelMuted = 1515,
  GroupMemberInfoSet = 1516,
  GroupMemberSetToAdmin = 1517,
  GroupMemberSetToOrdinaryUser = 1518,
  GroupAnnouncementUpdated = 1519,
  GroupNameUpdated = 1520,

  SuperGroupUpdated = 1651,
  MsgDeleted = 1652,

  BurnMessageChange = 1701,
  ConversationUnread = 1702,
  ClearConversation = 1703,

  BusinessNotification = 2001,

  // notification
  RevokeMessage = 2101,
  DeleteMsgs = 2102,
  PinMsg = 2103,
  HasReadReceipt = 2200,
}
export enum SessionType {
  Single = 1,
  Group = 3,
  WorkingGroup = 3,
  Notification = 4,
}
export enum GroupStatus {
  Normal = 0,
  Baned = 1,
  Dismissed = 2,
  Muted = 3,
}
export enum GroupAtType {
  AtNormal = 0,
  AtMe = 1,
  AtAll = 2,
  AtAllAtMe = 3,
  AtGroupNotice = 4,
}
export enum GroupMemberFilter {
  All = 0,
  Owner = 1,
  Admin = 2,
  Normal = 3,
  AdminAndNormal = 4,
  AdminAndOwner = 5,
}
export enum Relationship {
  isBlack = 0,
  isFriend = 1,
}
export enum LoginStatus {
  Logout = 1,
  Logging = 2,
  Logged = 3,
}
export enum OnlineState {
  Online = 1,
  Offline = 0,
}
export enum GroupMessageReaderFilter {
  Read = 0,
  UnRead = 1,
}
export enum ViewType {
  History = 0,
  Search = 1,
}
export enum GroupVisibility {
  Private = 0,
  Public = 1,
}
export enum PublicGroupJoinStatus {
  All = 0,
  Joined = 1,
  NotJoined = 2,
}
export enum GroupPermission {
  SendMessage = 'SEND_MESSAGE',
  PinMessage = 'PIN_MESSAGE',
  UpdateGroupName = 'UPDATE_GROUP_NAME',
  UpdateGroupAvatar = 'UPDATE_GROUP_AVATAR',
  UpdateGroupDescription = 'UPDATE_GROUP_DESCRIPTION',
  AddMember = 'ADD_MEMBER',
  RemoveMember = 'REMOVE_MEMBER',
  AddAdmin = 'ADD_ADMIN',
  TransferOwnership = 'TRANSFER_OWNERSHIP',
  ConfigGroupPermission = 'CONFIG_GROUP_PERMISSION',
  ViewMemberInformation = 'VIEW_MEMBER_INFORMATION',
}
export enum PeerType {
  Group = 'GROUP',
  Bot = 'BOT',
  User = 'USER',
  Customer = 'CUSTOMER'
}