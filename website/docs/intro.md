---
id: intro
title: Introduction
sidebar_position: 1
slug: /
---

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

## Platform Requirements

- **React Native:** v0.72+
- **iOS:** 12.0+
- **Android:** 6.0+ (API 21+)

## Where to Go Next

- [Quick Start](./quick-start) — init, login, send/receive your first message
- [System Architecture](./system-architecture) — how the JS ↔ Native ↔ Go bridge works, and the full `MessageType` routing table
- [API Reference](./api-reference) — every method, event, and type
- [Code Standards](./code-standards) — patterns to follow when contributing a new bridge method
- [Deployment & Integration](./deployment-guide) — installing this SDK into a consuming app

## License

Apache 2.0.
