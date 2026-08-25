---
id: code-standards
title: Code Standards
sidebar_position: 6
---


This document describes the established patterns, conventions, and architectural decisions that guide implementation across the JavaScript, Android, and iOS layers of the SDK.

## Overview

The SDK follows a **single responsibility principle:** the bridge adapts the Go SDK's callback-based interface to JavaScript Promises and TypeScript types. When adding a new API method, follow the established patterns to maintain consistency, type safety, and testability.

---

## Adding a New SDK Method: Reference Pattern

### Scenario

Suppose the Go SDK adds a new method `getGroupNotice(groupID)` that returns a string asynchronously.

### Step 1: Update TypeScript Layer (`src/`)

#### 1.1 Add Parameter Type (if needed) in `src/types/params.ts`

```typescript
// If method takes a single param object, add an interface
export interface GetGroupNoticeParams {
  groupID: string;
}

// If simple params, no new type needed; use primitives directly
```

#### 1.2 Add Entity Type (if needed) in `src/types/entity.ts`

```typescript
// If method returns a complex type, add an interface
export interface GroupNotice {
  content: string;
  updateTime: number;
  updatedBy: string;
}
```

#### 1.3 Add Enum (if needed) in `src/types/enum.ts`

```typescript
// Only if new concept introduces enumerable states
export enum NoticeType {
  Announcement = 1,
  Pinned = 2,
}
```

#### 1.4 Add Method to `src/sdk.ts`

```typescript
getGroupNotice(groupID: string, operationID: string = id()) {
  return this.invoke(NativeOpenIMSDK.getGroupNotice, [groupID, operationID]);
}
```

**Pattern:** 
- Method name matches Go SDK method name exactly
- Parameters match Go SDK signature (order-sensitive)
- Optional `operationID` param (auto-generated UUID v4 if omitted)
- `this.invoke()` wraps native call, handling Promise resolution and error wrapping

#### 1.5 Export from `src/index.tsx`

If adding a new type or enum, ensure it's exported from the root:

```typescript
export * from './types/entity';  // auto-exported
export { GroupNotice } from './types/entity'; // already covered by *
```

### Step 2: Update Native Layer (Android & iOS in Parallel)

#### Android: `android/src/main/java/com/openimsdkrn/OpenImSdkRnModule.java`

```java
@ReactMethod
public void getGroupNotice(
  String groupID,
  String operationID,
  Promise promise
) {
  try {
    BaseImpl callback = new BaseImpl(promise, operationID);
    String groupIDJson = groupID; // primitives don't need JSON serialization
    Open_im_sdk.getGroupNotice(callback, operationID, groupIDJson);
  } catch (Exception e) {
    OpenIMSdkCallback.rejectPromise(promise, e);
  }
}
```

**Pattern:**
- `@ReactMethod` decorator exposes to JS
- Final parameter is `Promise promise` (RN magic)
- Create a `BaseImpl` callback proxy (inherits from Go-generated `open_im_sdk_callback.Base`)
- Call the gomobile-generated static Go function `Open_im_sdk.methodName(...)`
- Wrap in try-catch; reject promise on exception

**For Complex Types** (objects), serialize to JSON first:

```java
@ReactMethod
public void setGroupInfo(ReadableMap params, String operationID, Promise promise) {
  try {
    BaseImpl callback = new BaseImpl(promise, operationID);
    String paramsJson = ReadableMapHelper.map2string(params); // custom helper
    Open_im_sdk.setGroupInfo(callback, operationID, paramsJson);
  } catch (Exception e) {
    OpenIMSdkCallback.rejectPromise(promise, e);
  }
}
```

#### iOS: `ios/OpenImSdkRn.m`

```objc
RCT_EXPORT_METHOD(
  getGroupNotice:(NSString *)groupID
  operationID:(NSString *)operationID
  resolver:(RCTPromiseResolveBlock)resolve
  rejecter:(RCTPromiseRejectBlock)reject
) {
  RNCallbackProxy *proxy = [[RNCallbackProxy alloc] initWithResolver:resolve
                                                             rejecter:reject
                                                          operationID:operationID];
  
  Open_im_sdkGetGroupNotice(proxy, operationID, groupID);
}
```

**Pattern:**
- `RCT_EXPORT_METHOD` decorator exposes to JS
- Parameters match exactly (order-sensitive)
- Final two params are `resolver` and `rejecter` (RN magic)
- Create callback proxy (inherits from Go-generated protocol)
- Call gomobile-generated C-style function `Open_im_sdkMethodName(...)`
- No try-catch needed; error handling delegated to proxy

**For Complex Types:**

```objc
RCT_EXPORT_METHOD(
  setGroupInfo:(NSDictionary *)params
  operationID:(NSString *)operationID
  resolver:(RCTPromiseResolveBlock)resolve
  rejecter:(RCTPromiseRejectBlock)reject
) {
  RNCallbackProxy *proxy = [[RNCallbackProxy alloc] initWithResolver:resolve
                                                             rejecter:reject
                                                          operationID:operationID];
  
  NSString *paramsJson = [NSJSONSerialization stringFromDictionary:params];
  Open_im_sdkSetGroupInfo(proxy, operationID, paramsJson);
}
```

### Step 3: Update Type Definitions

The JS SDK's `OpenIMSDK.native.ts` mirrors the native module interface. If you added a new method, add its signature:

```typescript
// src/OpenIMSDK.native.ts
interface NativeOpenIMSDK {
  getGroupNotice(groupID: string, operationID: string): Promise<string>;
  // ... other methods
}
```

### Step 4: Test

Run the example app on both platforms:

```sh
yarn example ios    # or yarn example android
```

Call the method from example app:

```typescript
try {
  const notice = await OpenIMSDK.getGroupNotice('group-123');
  console.log('Notice:', notice);
} catch (error) {
  console.error('Failed:', error);
}
```

Verify:
- Android: Check Java log output; ensure method executes without crashes
- iOS: Check Xcode console; ensure callback fires and resolves promise

---

## Special Cases

### Send Message with Progress Callback

Some operations emit progress events independent of the promise. Example: `sendMessage()` emits `SendMessageProgress` during upload.

**Android Implementation:**

```java
@ReactMethod
public void sendMessage(ReadableMap params, String operationID, Promise promise) {
  SendMsgCallBack callback = new SendMsgCallBack(promise, operationID, this.emitter);
  String paramsJson = ReadableMapHelper.map2string(params);
  Open_im_sdk.sendMessage(callback, operationID, paramsJson);
}

// SendMsgCallBack wires both progress and completion:
public class SendMsgCallBack extends open_im_sdk_callback.Base {
  private Promise promise;
  private String operationID;
  private Emitter emitter;

  public SendMsgCallBack(Promise promise, String operationID, Emitter emitter) {
    this.promise = promise;
    this.operationID = operationID;
    this.emitter = emitter;
  }

  @Override
  public void onSuccess(String data) {
    // Parse JSON, resolve promise
    promise.resolve(data);
  }

  @Override
  public void onError(int errCode, String errMsg) {
    promise.reject(String.valueOf(errCode), errMsg);
  }

  @Override
  public void onProgress(long current, long total) {
    // Emit progress event
    WritableMap progress = Arguments.createMap();
    progress.putDouble("progress", (double) current / total);
    progress.putString("message", operationID);
    emitter.send("SendMessageProgress", progress);
  }
}
```

**iOS Implementation:**

```objc
RCT_EXPORT_METHOD(
  sendMessage:(NSDictionary *)params
  operationID:(NSString *)operationID
  resolver:(RCTPromiseResolveBlock)resolve
  rejecter:(RCTPromiseRejectBlock)reject
) {
  RNSendMessageCallbackProxy *proxy = [[RNSendMessageCallbackProxy alloc]
    initWithResolver:resolve
            rejecter:reject
         operationID:operationID
       eventEmitter:self];
  
  NSString *paramsJson = [NSJSONSerialization stringFromDictionary:params];
  Open_im_sdkSendMessage(proxy, operationID, paramsJson);
}

// In RNSendMessageCallbackProxy.m:
- (void)onProgress:(long)current total:(long)total {
  NSDictionary *progress = @{
    @"progress": @((double)current / total),
    @"message": self.operationID
  };
  [self.eventEmitter sendEventWithName:@"SendMessageProgress" body:progress];
}
```

### Synchronous Methods (No Callback)

Some Go methods return directly without invoking a callback. Example: `getLoginStatus()`.

**Android:**

```java
@ReactMethod
public void getLoginStatus(String operationID, Promise promise) {
  try {
    int status = Open_im_sdk.getLoginStatus();
    promise.resolve(status);
  } catch (Exception e) {
    promise.reject(String.valueOf(e.hashCode()), e.getMessage());
  }
}
```

**iOS:**

```objc
RCT_EXPORT_METHOD(
  getLoginStatus:(NSString *)operationID
  resolver:(RCTPromiseResolveBlock)resolve
  rejecter:(RCTPromiseRejectBlock)reject
) {
  int status = Open_im_sdkGetLoginStatus();
  resolve(@(status));
}
```

**JS:**

```typescript
getLoginStatus(operationID: string = id()) {
  return this.invoke(NativeOpenIMSDK.getLoginStatus, [operationID]);
}
```

---

## Go Type → TypeScript Type Mapping

The `release-openim-sdk` skill generates TS types from Go structs. Maintain these conventions:

| Go | TypeScript | Example |
|----|-----------| ---------|
| `string` | `string` | `UserID: string` |
| `int`, `int32`, `int64` | `number` | `Age: number` |
| `uint32`, `uint64` | `number` | `Permissions: number` |
| `bool` | `boolean` | `IsAdmin: boolean` |
| `[]T` | `T[]` | `[]string` → `string[]` |
| `map[K]V` | `Record<K, V>` | `map[string]string` → `Record<string, string>` |
| Struct field `UserID` | `userID` (camelCase) | Convert snake_case to camelCase |
| Enum iota | Numeric enum | `const Group = 2` → `Group = 2` |
| `*Struct` (optional) | `Struct \| undefined` | Omit from interface if always present |
| `time.Time` (epoch ms) | `number` | Milliseconds since Unix epoch |

**Never use `any`** in public API surfaces. If a type is unknown, use `unknown` and cast explicitly in code.

---

## Listener Registration Pattern

When `initSDK()` is called, the bridge registers long-lived listeners with the Go SDK. This pattern ensures events flow from native layers to JS.

**Android Pattern:**

```java
// In initSDK method:
public void initSDK(ReadableMap params, String operationID, Promise promise) {
  // ... other init logic ...

  // Register all listeners
  UserListenerImpl userListener = new UserListenerImpl(emitter);
  Open_im_sdk.setUserListener(userListener);
  
  ConversationListenerImpl convListener = new ConversationListenerImpl(emitter);
  Open_im_sdk.setConversationListener(convListener);
  
  // ... register other listeners ...
}

// Listener implementation:
public class UserListenerImpl extends open_im_sdk_listener.User {
  private Emitter emitter;

  public UserListenerImpl(Emitter emitter) {
    this.emitter = emitter;
  }

  @Override
  public void onSelfInfoUpdated(String data) {
    // data is JSON string from Go
    emitter.send("onSelfInfoUpdated", data);
  }
}
```

**iOS Pattern:**

```objc
// In initSDK method:
- (void)initSDK:(NSDictionary *)params
    operationID:(NSString *)operationID
       resolver:(RCTPromiseResolveBlock)resolve
       rejecter:(RCTPromiseRejectBlock)reject
{
  // ... other init logic ...

  RNUserListenerImpl *userListener = [[RNUserListenerImpl alloc] initWithEventEmitter:self];
  Open_im_sdkSetUserListener(userListener);
  
  RNConversationListenerImpl *convListener = [[RNConversationListenerImpl alloc] initWithEventEmitter:self];
  Open_im_sdkSetConversationListener(convListener);
  
  // ... register other listeners ...
}

// Listener implementation:
@interface RNUserListenerImpl : NSObject<Open_im_sdkUserListener>
@property (nonatomic, weak) OpenImSdkRn *eventEmitter;
@end

@implementation RNUserListenerImpl

- (void)onSelfInfoUpdated:(NSString *)data {
  [self.eventEmitter pushEvent:@"onSelfInfoUpdated" data:data];
}

@end
```

---

## Error Handling Pattern

All errors from native calls are wrapped into `OpenIMApiError` on the JS side.

**Contract:** Native rejects with `{code: number, message: string}` → JS throws `OpenIMApiError(code, message, operationID)`.

**Android:**

```java
// BaseImpl.onError receives error from Go
@Override
public void onError(int errCode, String errMsg) {
  WritableMap errorMap = Arguments.createMap();
  errorMap.putInt("code", errCode);
  errorMap.putString("message", errMsg);
  promise.reject(String.valueOf(errCode), errMsg);
}
```

**iOS:**

```objc
- (void)onError:(NSInteger)code message:(NSString *)message {
  NSError *error = [NSError errorWithDomain:@"OpenIM" code:code userInfo:@{
    NSLocalizedDescriptionKey: message
  }];
  reject([@(code) stringValue], message, error);
}
```

**JS:**

```typescript
// src/sdk.ts invoke() method
catch (error: any) {
  throw new OpenIMApiError(error.code, error.message, args[args.length - 1]);
}
```

---

## Testing Patterns

### Unit Test Structure

```typescript
// tests/sdk.test.ts
import OpenIMSDK from '../src/sdk';

describe('OpenIMSDK', () => {
  beforeAll(async () => {
    await OpenIMSDK.initSDK({
      apiAddr: 'http://localhost:10002',
      wsAddr: 'ws://localhost:10001',
      dataDir: '/tmp',
      logFilePath: '/tmp',
    });
  });

  it('should create text message', async () => {
    const msg = await OpenIMSDK.createTextMessage('hello');
    expect(msg.contentType).toBe(MessageType.TextMessage);
    expect(msg.textElem?.content).toBe('hello');
  });

  afterAll(async () => {
    await OpenIMSDK.unInitSDK();
  });
});
```

### Integration Test Pattern

Test against a real OpenIM server instance (Docker):

```sh
docker run -d \
  -p 10001:10001 \
  -p 10002:10002 \
  openim-server:latest

# Run tests
yarn test:integration
```

---

## Known Limitations & Code Debt

### 1. iOS JSON Serialization Duplication

**Issue:** `NSMutableDictionary+JSON.h/m` category (JSON serialization helpers) is copy-pasted across multiple iOS bridge files instead of shared once.

**Impact:** Maintenance burden; changes to JSON serialization logic need to be applied in 3+ places.

**Workaround:** Extract to `ios/Shared/JSONHelper.h/m` and import across all bridge files.

### 2. Android/iOS Custom Business Listener

**Issue:** `SetCustomBusinessListener` (Android) / `OnSignalingListener` (iOS) callback handlers exist but are never wired to emit events.

**Impact:** Reserved for future signaling (call, video) features; currently non-functional.

**Status:** Documented in `docs/system-architecture.md` under "Known Limitations."

### 3. Upload Progress Sub-callbacks

**Issue:** `UploadFileCallbackProxy` implements multiple progress callbacks, but only completion and upload-complete are routed to JS. Sub-callbacks are no-ops.

**Workaround:** If detailed progress tracking is needed, enhance the proxy to wire all callbacks.

---

## Review Checklist for New Methods

Before submitting a PR that adds or modifies an SDK method:

- [ ] TypeScript method added to `src/sdk.ts`
- [ ] Types added to `src/types/params.ts` or `src/types/entity.ts` (if needed)
- [ ] Enums added to `src/types/enum.ts` (if needed)
- [ ] Android `@ReactMethod` added with proper error handling
- [ ] iOS `RCT_EXPORT_METHOD` added with proper error handling
- [ ] Types exported from `src/index.tsx`
- [ ] Event listener registered in `initSDK()` (if applicable)
- [ ] Example/test code in `example/src/App.tsx` demonstrates new method
- [ ] No `any` types in public API
- [ ] Parameter order matches Go SDK exactly
- [ ] Method name matches Go SDK exactly
- [ ] Error handling tested (invalid params, network failure, auth failure)

---

## Maintenance Philosophy

1. **Stay in Sync with Upstream:** When `openimsdk-core` releases a new version, update TS types, bridges, and docs to reflect API changes.

2. **Minimize Breaking Changes:** Deprecate old APIs; introduce new ones; don't delete without a 2-release notice.

3. **Type Safety First:** Invest in type definitions; catch bugs at compile-time, not runtime.

4. **Documentation is Code:** Update docs alongside implementation. A method without docs is not done.

5. **Test Coverage:** Aim for 80%+ coverage on JS layer; bridge methods tested via example app on real devices.
