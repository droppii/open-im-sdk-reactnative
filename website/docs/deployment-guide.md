---
id: deployment-guide
title: Deployment & Integration
sidebar_position: 7
---


This guide covers how to install, configure, and integrate `@droppii/openim-rn-client-sdk` into your React Native application.

## Prerequisites

- **Node.js:** v16+
- **React Native:** v0.72+
- **iOS:** macOS 13+, Xcode 14+, iOS 12+ target
- **Android:** Android Studio 2021.1+, Android SDK 21+ (API level 5.0+)
- **OpenIM Server:** Self-hosted instance (URL required at init time)

---

## Installation

### Step 1: Install Package

```bash
npm install @droppii/openim-rn-client-sdk
# or yarn
yarn add @droppii/openim-rn-client-sdk
```

### Step 2: Link Native Modules (Usually Automatic)

React Native v0.60+ uses **autolinking**. Verify native modules are linked:

```bash
# Check Android:
cat android/settings.gradle | grep openim-rn

# Check iOS:
cat ios/Podfile | grep openim-rn-client-sdk
```

If not found, manually link:

```bash
# For older RN versions (< 0.60)
react-native link @droppii/openim-rn-client-sdk
```

### Step 3: iOS-Specific: Install Pods

```bash
cd ios
pod install --repo-update
cd ..
```

**Troubleshooting:** See [iOS build troubleshooting guide](https://github.com/droppii/open-im-sdk-reactnative/blob/main/docs/IOS-EXAMPLE-WARN.md) for common pod installation issues.

### Step 4: Android-Specific: Ensure Gradle Compatibility

Open `android/app/build.gradle`:

```gradle
android {
  compileSdkVersion 33  // or higher
  defaultConfig {
    targetSdkVersion 33  // or higher
    minSdkVersion 21     // minimum supported
  }
  // Ensure your build.gradle includes native-libs:
  repositories {
    flatDir {
      dirs 'node_modules/@droppii/openim-rn-client-sdk/android/native-libs'
    }
  }
}
```

The native `.aar` is automatically included via autolinking.

### Step 5: Test Installation

```bash
# Run example app to verify native linking
yarn example ios    # or yarn example android
```

If the example runs without crashes, installation is successful.

---

## Configuration

### Initialize SDK at App Startup

The SDK must be initialized **before any other methods are called**. Typically do this in your app's root component or in an auth context:

```typescript
import React, { useEffect } from 'react';
import OpenIMSDK from '@droppii/openim-rn-client-sdk';
import RNFS from 'react-native-fs';

export const App: React.FC = () => {
  useEffect(() => {
    initializeSDK();
  }, []);

  const initializeSDK = async () => {
    try {
      // Ensure data directory exists
      const dataDir = RNFS.DocumentDirectoryPath + '/openim';
      await RNFS.mkdir(dataDir);

      // Initialize SDK with server addresses
      await OpenIMSDK.initSDK({
        apiAddr: 'http://<your-openim-server>:10002',
        wsAddr: 'ws://<your-openim-server>:10001',
        dataDir: dataDir,
        logFilePath: dataDir,
        logLevel: 4,  // Info level
        isLogStandardOutput: false,  // Don't log to stdout in production
      });

      console.log('SDK initialized successfully');
    } catch (error) {
      console.error('SDK init failed:', error);
    }
  };

  return (
    // Your app components...
  );
};
```

**InitOptions Details:**

| Field | Type | Required | Example |
|-------|------|----------|---------|
| `apiAddr` | string | Yes | `'http://openim.example.com:10002'` |
| `wsAddr` | string | Yes | `'ws://openim.example.com:10001'` |
| `dataDir` | string | Yes | `RNFS.DocumentDirectoryPath + '/openim'` |
| `logFilePath` | string | Yes | `RNFS.DocumentDirectoryPath + '/openim'` |
| `logLevel` | number | No | 0–5 (Panic to Debug); default: 4 |
| `isLogStandardOutput` | boolean | No | Default: `false` |

**Important:** `dataDir` and `logFilePath` must exist and be writable. The SDK stores SQLite databases here.

### Connect to Your OpenIM Server

OpenIM requires valid credentials. You **cannot** create tokens in this SDK — you must obtain them from your app's authentication backend.

#### Flow:

1. **Your App's Auth System** → Authenticates user (via your own login UI)
2. **Your Backend API** → Calls OpenIM's user registration/token API
3. **Your Backend Returns** → `{userID: "...", token: "..."}`
4. **React Native App** → Passes credentials to OpenIMSDK

**Example (Pseudo-code):**

```typescript
const handleLogin = async (email: string, password: string) => {
  try {
    // Step 1: Authenticate with YOUR backend
    const authResponse = await fetch('https://your-api.com/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    const { userID, token } = await authResponse.json();

    // Step 2: Login to OpenIM using credentials from your backend
    await OpenIMSDK.login({ userID, token });

    console.log('Logged in to OpenIM');
  } catch (error) {
    console.error('Login failed:', error);
  }
};
```

**Where does the token come from?**

Your backend must implement OpenIM's token API. See OpenIM docs: [User Token Management](https://docs.openim.io/restapi/apis/usermanagement/userregister).

---

## Integration Patterns

### Pattern 1: Context Provider (Recommended)

```typescript
// OpenIMContext.tsx
import React, { createContext, useEffect, useCallback, ReactNode } from 'react';
import OpenIMSDK, { OpenIMEvent } from '@droppii/openim-rn-client-sdk';

interface OpenIMContextType {
  isInitialized: boolean;
  isLoggedIn: boolean;
  error: string | null;
}

export const OpenIMContext = createContext<OpenIMContextType>({
  isInitialized: false,
  isLoggedIn: false,
  error: null,
});

export const OpenIMProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [state, setState] = React.useState({
    isInitialized: false,
    isLoggedIn: false,
    error: null as string | null,
  });

  useEffect(() => {
    const initSDK = async () => {
      try {
        await OpenIMSDK.initSDK({ /* config */ });
        setState(prev => ({ ...prev, isInitialized: true }));

        // Listen for connection changes
        OpenIMSDK.on(OpenIMEvent.OnConnectSuccess, () => {
          setState(prev => ({ ...prev, isLoggedIn: true, error: null }));
        });

        OpenIMSDK.on(OpenIMEvent.OnConnectFailed, ({ errMsg }) => {
          setState(prev => ({ ...prev, error: errMsg }));
        });

        OpenIMSDK.on(OpenIMEvent.OnKickedOffline, () => {
          setState(prev => ({ ...prev, isLoggedIn: false }));
        });
      } catch (error: any) {
        setState(prev => ({ ...prev, error: error.message }));
      }
    };

    initSDK();

    // Cleanup
    return () => {
      OpenIMSDK.off(OpenIMEvent.OnConnectSuccess, () => {});
      // ... unsubscribe from other events
    };
  }, []);

  return (
    <OpenIMContext.Provider value={state}>
      {children}
    </OpenIMContext.Provider>
  );
};

// Usage in your app:
export const App = () => (
  <OpenIMProvider>
    <YourRootComponent />
  </OpenIMProvider>
);
```

### Pattern 2: Hook-Based Access

```typescript
// useOpenIM.ts
import { useContext } from 'react';
import OpenIMSDK from '@droppii/openim-rn-client-sdk';
import { OpenIMContext } from './OpenIMContext';

export const useOpenIM = () => {
  const context = useContext(OpenIMContext);
  if (!context) {
    throw new Error('useOpenIM must be used within OpenIMProvider');
  }
  return { sdk: OpenIMSDK, context };
};

// Usage:
const MyComponent = () => {
  const { sdk, context } = useOpenIM();
  const [conversations, setConversations] = React.useState([]);

  React.useEffect(() => {
    const loadConversations = async () => {
      const list = await sdk.getConversationListSplit({ offset: 0, count: 20 });
      setConversations(list);
    };

    if (context.isLoggedIn) {
      loadConversations();
    }
  }, [context.isLoggedIn]);

  return (
    // Render conversations...
  );
};
```

### Pattern 3: Redux Integration (if using Redux)

```typescript
// slices/openIMSlice.ts
import { createSlice } from '@reduxjs/toolkit';
import OpenIMSDK from '@droppii/openim-rn-client-sdk';

const openIMSlice = createSlice({
  name: 'openIM',
  initialState: {
    isInitialized: false,
    isLoggedIn: false,
    conversations: [],
  },
  reducers: {
    setInitialized(state) {
      state.isInitialized = true;
    },
    setLoggedIn(state) {
      state.isLoggedIn = true;
    },
    setConversations(state, action) {
      state.conversations = action.payload;
    },
  },
});

// Thunks for side effects:
export const initOpenIM = () => async (dispatch) => {
  try {
    await OpenIMSDK.initSDK({ /* config */ });
    dispatch(setInitialized());
  } catch (error) {
    console.error('Init failed:', error);
  }
};

export default openIMSlice.reducer;
```

---

## Development vs. Production

### Development

**Use `http://` and `ws://` (unencrypted) for easier debugging:**

```typescript
const isDev = __DEV__; // React Native's built-in flag
await OpenIMSDK.initSDK({
  apiAddr: isDev ? 'http://localhost:10002' : 'https://api.prod.com:10002',
  wsAddr: isDev ? 'ws://localhost:10001' : 'wss://api.prod.com:10001',
  logLevel: isDev ? 5 : 2,  // Debug in dev, Error in prod
  // ...
});
```

### Production

**Use `https://` and `wss://` (encrypted):**

```typescript
await OpenIMSDK.initSDK({
  apiAddr: 'https://api.example.com:10002',
  wsAddr: 'wss://api.example.com:10001',
  logLevel: 2,  // Error level only
  isLogStandardOutput: false,  // No stdout logging
  // ...
});
```

---

## Error Handling

All SDK errors throw `OpenIMApiError`:

```typescript
import { OpenIMApiError } from '@droppii/openim-rn-client-sdk';

try {
  await OpenIMSDK.sendMessage({ recvID: 'u1', groupID: '', message });
} catch (error) {
  if (error instanceof OpenIMApiError) {
    console.error(`[${error.operationID}] Error ${error.code}: ${error.message}`);
    
    // Handle specific errors
    switch (error.code) {
      case 1001:
        console.error('User not found');
        break;
      case 1100:
        console.error('Friend not found');
        break;
      case 1200:
        console.error('Group not found');
        break;
      default:
        console.error('Unknown error');
    }
  }
}
```

---

## Expo Support

**Supported from v1.0.0-rc30+** via the custom dev client (prebuild) workflow. Expo Go is not supported.

### Setup

```bash
# Install Expo modules
npm install expo-dev-client

# Add OpenIM SDK
npm install @droppii/openim-rn-client-sdk

# Build custom dev client
npx expo prebuild --clean

# Run on simulator/device
npx expo run:ios    # or npx expo run:android
```

### Key Difference

Unlike standard React Native, you build and deploy a custom dev client instead of using the generic Expo Go app. The custom client includes the native OpenIM SDK.

---

## Troubleshooting

### "Module NativeOpenIMSDK does not exist"

**Cause:** Native modules not linked.

**Solution:**
```bash
# Verify autolinking
react-native config | grep openim-rn-client-sdk

# If not listed, manually link (for RN < 0.60)
react-native link @droppii/openim-rn-client-sdk

# Clean and rebuild
rm -rf ios/Pods && cd ios && pod install && cd ..
cd android && ./gradlew clean && cd ..

# Restart Metro bundler
npm start -- --reset-cache
```

### iOS Pod Installation Fails

See [iOS build troubleshooting guide](https://github.com/droppii/open-im-sdk-reactnative/blob/main/docs/IOS-EXAMPLE-WARN.md) for iOS-specific solutions.

### Android Gradle Build Fails

**Ensure Android SDK versions match:**

```gradle
// android/build.gradle
ext {
  compileSdkVersion = 33
  targetSdkVersion = 33
  minSdkVersion = 21
}
```

Clear cache and rebuild:
```bash
cd android && ./gradlew clean && ./gradlew build && cd ..
```

### Connection Refused Error

**Cause:** OpenIM server not reachable at configured URL.

**Check:**
```bash
# Verify OpenIM server is running
curl http://<your-server>:10002/health

# On Android emulator, use 10.0.2.2 instead of localhost
await OpenIMSDK.initSDK({
  apiAddr: 'http://10.0.2.2:10002',  // Android emulator special IP
  wsAddr: 'ws://10.0.2.2:10001',
  // ...
});
```

### "Token Invalid" Error

**Cause:** JWT token expired or invalid signature.

**Solution:**
1. Verify token issued by your OpenIM server
2. Check token expiration time (`exp` claim in JWT)
3. Ensure `userID` in token matches login `userID`
4. Re-issue token if expired

```typescript
// Decode token to check expiration (npm install jwt-decode)
import jwtDecode from 'jwt-decode';

const decoded = jwtDecode(token);
console.log('Token expires:', new Date(decoded.exp * 1000));
```

---

## Next Steps

1. **Read the Quick Start** — `README.md` section "Quick Start"
2. **Explore Example App** — `example/src/App.tsx` demonstrates all major workflows
3. **API Reference** — `docs/codebase-summary.md` lists all 60+ methods
4. **Message Types** — `docs/system-architecture.md` explains which events deliver which messages
5. **Architecture** — `docs/system-architecture.md` describes the bridge design

---

## Release Pipeline (For Maintainers)

**Note:** This section is for the SDK maintainers, not consuming apps.

When a new `openimsdk-core` version is released:

1. Use the `release-openim-sdk` skill to build new AAR/xcframework
2. Update native artifacts in `native-libs/`
3. Update TypeScript types from Go structs
4. Sync Android/iOS bridges if Go signatures changed
5. Test example app on real devices
6. Tag release in git
7. Publish to npm: `npm publish`
8. Update changelog: `docs/project-changelog.md`

See `docs/code-standards.md` for detailed bridge contribution guidelines.

---

## Support

- **API Questions?** See `docs/codebase-summary.md`
- **Architecture Questions?** See `docs/system-architecture.md`
- **Contributing?** See `docs/code-standards.md`
- **Issues?** Open GitHub issue with platform, RN version, and steps to reproduce
- **Slack?** Join the OpenIM Slack for community support

---

## License

Apache 2.0 — see [LICENSE](https://github.com/droppii/open-im-sdk-reactnative/blob/main/LICENSE).
