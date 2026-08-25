# Project Roadmap

## Project Nature

This package is **a wrapper, not an independent project**. It maintains **strict version parity with the upstream `openimsdk-core` Go SDK**. There is no separate feature roadmap; instead, this roadmap tracks:

1. Sync status with upstream Go SDK releases
2. Release/build pipeline operational status
3. Documentation completeness
4. Known limitations & technical debt

---

## Versioning Scheme

**Format:** `v<MAJOR>.<MINOR>.<PATCH>-rc<BUILD>`

Example: `v1.0.0-rc30`

- **MAJOR.MINOR.PATCH** — Tracks upstream `openimsdk-core` version (e.g., core `0.0.1-rc23` → SDK `v1.0.0-rc30`)
- **-rc<BUILD>** — Build number when multiple SDK releases target the same Go core version

**Release Cadence:** Every 1–3 weeks (aligned with OpenIM community releases)

---

## Current Release Status

### Latest Release: **v1.0.0-rc30** (2026-08-21)

| Component | Version | Status |
|-----------|---------|--------|
| OpenIM Core (Go) | 0.0.1-rc23 | Current |
| React Native Bridge | v1.0.0-rc30 | Stable |
| TypeScript Types | Synced | ✅ |
| Android Bridge | Synced | ✅ |
| iOS Bridge | Synced | ✅ |
| Documentation | Complete | ✅ |
| npm Package | Published | ✅ |
| Expo Support | v1.0.0-rc30+ | ✅ |

---

## Release Pipeline Status

### ✅ Operational Phases

1. **Upstream Monitoring** — Watch `openimsdk-core` releases
2. **Native Build** — Use `release-openim-sdk` skill to:
   - Pull Go source at target tag
   - Run gomobile build (AAR + xcframework)
   - Copy artifacts to `native-libs/`
   - Detect breaking changes in Go API
3. **Bridge Updates** — Sync Android/iOS bridges if Go signatures changed
4. **Type Generation** — Re-generate TypeScript types from updated Go structs
5. **Testing** — Run example app on iOS + Android simulators
6. **Release** — Tag git, publish to npm, update docs

**Typical turnaround:** ~1 day from upstream release to npm publication

---

## Roadmap Phases

### Phase 1: Initial Release (Status: **COMPLETE** ✅)

**Goal:** Establish stable v1.0.0-rc30 with complete documentation and type safety.

**Completed:**
- ✅ Full TypeScript bridge layer (~2700 LOC)
- ✅ Android Java bridge + gomobile integration
- ✅ iOS Objective-C bridge + gomobile integration
- ✅ 60+ typed methods covering all major features
- ✅ ~45 real-time events
- ✅ Complete API reference documentation
- ✅ Example app demonstrating all major workflows
- ✅ Type definitions for 100+ data shapes
- ✅ 22 enums covering all state/config options
- ✅ operationID parameter auto-generation
- ✅ Error handling with OpenIMApiError wrapper

### Phase 2: Ongoing Maintenance (Status: **ACTIVE**)

**Goal:** Keep synchronized with upstream; maintain stability and documentation.

**Current Work:**
- Monitor upstream `openimsdk-core` releases
- Update native artifacts (AAR/xcframework) when new version released
- Sync TypeScript types with Go struct changes
- Re-run tests on new Android/iOS SDKs
- Update `codebase-summary.md` if API changes
- Respond to issues and fix bugs

**Timeline:** Ongoing; new releases every 1–3 weeks

**Success Metrics:**
- npm downloads > 100/month
- < 5 issues/month (vs. bugs or API misuse)
- 95%+ successful npm install + pod install (iOS)
- No security vulnerabilities in dependencies

### Phase 3: Known Limitations (Status: **DOCUMENTED**)

| Limitation | Workaround | Priority |
|------------|-----------|----------|
| Android `SetCustomBusinessListener` not wired | Reserved for future signaling SDKs | Low |
| iOS JSON serialization duplicated across files | Extract to shared utility file | Medium |
| `UploadFileCallbackProxy` sub-callbacks stubs | Enhance if detailed progress tracking needed | Low |
| `UserListener` lifecycle events not exposed | Implement if needed for user command tracking | Low |

---

## What's NOT on the Roadmap

**Features explicitly out of scope** (maintained by upstream):

- Call/video communication (separate SDK)
- End-to-end encryption (server-side)
- File download caching strategies
- Chat UI components
- Call UI (dialing, ongoing call, etc.)
- Push notification orchestration

**Breaking Changes:** Will not introduce; deprecated APIs supported for ≥2 releases before removal.

---

## Dependency Updates

### Native Dependencies

- **iOS:** Minimum iOS 12.0; Xcode 14+ required
- **Android:** Minimum API 21 (Android 5.0); Gradle 7.0+
- **React Native:** v0.72+

### Go Core Dependency

Follows `openimsdk-core` upstream. See [openimsdk-core releases](https://github.com/openimsdk/openim-sdk-core/releases).

### npm Dependencies

Minimal external dependencies; primary dependencies:
- `react-native` (peer dependency)
- `tslib` (utility types)
- No runtime dependencies on external libraries (by design)

---

## Documentation Roadmap

### Completed ✅

- `README.md` — Quick start & installation
- `docs/project-overview-pdr.md` — Scope & requirements
- `docs/system-architecture.md` — Bridge design + MessageType table (critical)
- `docs/code-standards.md` — Patterns for contributors
- `docs/codebase-summary.md` — Complete API reference
- `docs/project-roadmap.md` — This file
- `docs/deployment-guide.md` — Install & integration
- `docs/IOS-EXAMPLE-WARN.md` — iOS troubleshooting

### Planned

- Integration guide: "Adding OpenIM Chat to Your App" (step-by-step walkthrough)
- Video tutorials: Init → Login → Send/Receive (YouTube)
- FAQ: "Why is my message not delivered?" and "How do I handle connection loss?" etc.
- Architecture diagram (Mermaid/ASCII)
- Troubleshooting guide: Common errors and solutions

---

## Timeline

| Date | Milestone | Status |
|------|-----------|--------|
| 2026-08-21 | v1.0.0-rc30 released with complete docs | ✅ Completed |
| 2026-09-30 | Upstream follow-up (v0.0.1-rc24 or later) | Pending |
| 2026-10-31 | Additional integration guides & tutorials | Backlog |
| 2027-Q1 | v1.1.0 (stable release if no breaking changes) | Planned |

---

## Support & Communication

**Issues:** Report bugs via GitHub issues. Clearly state platform (iOS/Android), React Native version, and steps to reproduce.

**Discussions:** Use GitHub discussions for questions and feature requests.

**Office Hours:** Weekly sync on Thursday 2 PM UTC (OpenIM community call) — join the [Slack workspace](https://join.slack.com/t/openimsdk/shared_invite/zt-2ijy1ys1f-O0aEDCr7ExRZ7mwsHAVg9A).

---

## Success Definition

This project is successful when:

1. ✅ **Developers can integrate messaging in < 1 hour** (init, login, send, receive)
2. ✅ **TypeScript provides full IDE autocomplete** (no `any` types in public API)
3. ✅ **Documentation answers 90% of "how to" questions** without needing support
4. ✅ **Stability:** < 1 crash per 1000 sessions over a quarter
5. ✅ **Adoption:** > 500 weekly npm downloads; > 50 GitHub stars

---

## Code Quality Goals

- **TypeScript:** All public APIs fully typed; no `any` leakage
- **Type Coverage:** 100% of return types; 100% of param types
- **Example App:** Demonstrates init, login, 1-to-1 messaging, group messaging, friend workflow, group management
- **Testing:** Example app is de-facto integration test (manual on real devices)
- **Documentation:** Every method/event documented with params, returns, and examples
- **Error Handling:** All API failures wrapped in `OpenIMApiError` with operation tracing

---

## For Contributors

See `docs/code-standards.md` for:
- How to add a new API method
- Native bridge patterns (Android & iOS)
- Type generation conventions
- Testing strategies

**Contribution Process:**
1. Fork repository
2. Create feature branch
3. Follow `code-standards.md`
4. Add/update types, Android, iOS, tests
5. Update docs if API changed
6. Submit PR (maintainer reviews within 1 week)

---

## Upstream Changes We Track

| Change Type | Impact | Action |
|-------------|--------|--------|
| New Go method | Add TypeScript method + Android + iOS bridges | ~1 day |
| Param struct field added/removed | Update TypeScript types + bridges | ~2 hours |
| Enum value added | Update TypeScript enum | ~30 min |
| Error code changes | Update error docs | ~1 hour |
| Build system changes | Update build instructions | ~2 hours |

---

## Questions?

- **API Questions?** See `docs/codebase-summary.md` (comprehensive reference)
- **Architecture Questions?** See `docs/system-architecture.md` (MessageType table critical)
- **Integration Questions?** See `README.md` and `docs/deployment-guide.md`
- **Contributing?** See `docs/code-standards.md`

Still stuck? Open an issue or reach out on Slack.
