# 12 — Decision Log (ADR)

## ADR-001: Flutter over Native Android
**Date:** 2026-07-04
**Decision:** Use Flutter instead of Kotlin/Compose
**Rationale:** Single codebase for iOS+Android, existing Flutter expertise, CarSah swarm reuse
**Consequences:** Larger APK, non-native feel, SSE streaming requires custom implementation

## ADR-002: Direct API Server over hermes-webui
**Date:** 2026-07-04
**Decision:** Connect directly to Hermes Agent API Server (port 8642), skip hermes-webui
**Rationale:** No middleware dependency, OpenAI-compatible API, Nous-supported
**Consequences:** Must enable API_SERVER_ENABLED in Hermes config

## ADR-003: Riverpod over BLoC
**Date:** 2026-07-04
**Decision:** Riverpod for state management
**Rationale:** Proven in CarSah, simpler than BLoC, excellent testability
**Consequences:** Team familiarity required

---

## Phase 2 Implementation Decisions (2026-07-05)

### ADR-004: Raw HttpClient SSE over third-party libraries
**Date:** 2026-07-05
**Decision:** Use `dart:io HttpClient` for SSE streaming instead of third-party SSE packages
**Rationale:** Flutter SSE library ecosystem immature — no production-ready package. Custom implementation is straightforward (parse `data: {...}\n\n`)
**Consequences:** Manual SSE parsing required; no built-in reconnection; integration tests needed
**References:** LL-002

### ADR-005: Notifier (not AutoDisposeNotifier) for data providers
**Date:** 2026-07-05
**Decision:** Feature data providers (sessions, tasks, skills) extend `Notifier` rather than `AutoDisposeNotifier`
**Rationale:** Tab navigation causes widget tree rebuilds; AutoDisposeNotifier discards cached server data on tab switch. Notifier survives navigation.
**Consequences:** Providers must be manually disposed if needed; memory footprint slightly higher
**References:** LL-003, DEC-034 rule 2

### ADR-006: isBusy flag for mutation guard
**Date:** 2026-07-05
**Decision:** Use a simple `isBusy` boolean in provider state to prevent duplicate mutation requests
**Rationale:** Provider-level flag is atomic across all listeners; widget-level debouncing can be bypassed by rapid state changes
**Consequences:** Every mutation action must check and set isBusy; adds boilerplate to providers
**References:** LL-004

### ADR-007: Static routes before parameterized routes in GoRouter
**Date:** 2026-07-05
**Decision:** Define static sub-routes (`/tasks/new`) before parameterized routes (`/tasks/:id`) in GoRouter configuration
**Rationale:** GoRouter matches first fitting route; `:id` captures any segment including "new"
**Consequences:** Route ordering is load-bearing; must be documented and enforced in code review
**References:** LL-005

### ADR-008: Nullable ApiClient with safe defaults in repositories
**Date:** 2026-07-05
**Decision:** Repositories accept nullable `ApiClient` and return safe defaults (empty lists) when no server connected
**Rationale:** Providers may be read before server connection; null-safe graceful degradation prevents runtime errors
**Consequences:** All repositories follow same pattern; tests must cover null ApiClient case
**References:** LL-006

### ADR-009: Widget-layer provider invalidation
**Date:** 2026-07-05
**Decision:** Providers must NOT call `ref.invalidate` internally; invalidation belongs in widget layer
**Rationale:** Internal invalidation creates circular dependency chains in Riverpod's dependency graph, breaking tests
**Consequences:** Widget layer must handle invalidation; providers are simpler and more testable
**References:** LL-007

---

## Phase 0 / HERMEX-008 Decisions (2026-07-15)

### ADR-010: HermesProfile as a First-Class Isar Entity
**Date:** 2026-07-15
**Status:** ACCEPTED (owner-approved)
**Decision:** Introduce `HermesProfile` as a first-class Isar entity extending the concept of server profiles with per-profile UX-layer fields: `defaultModelId` (String?), `reasoningEffort` (String? enum: minimal/low/medium/high/max), `isActive` (bool). The existing `ServerConfig` model retains its role for connection/auth data (id, name, url, apiKey) stored in secure storage; `HermesProfile` is the UX-layer entity for profile-level user preferences.
**Rationale:** Currently `ServerConfig` only carries id/name/url/isDefault/lastConnected — there is no place to persist per-profile model preference or reasoning depth. Without this entity, model selection (F-002) and reasoning-effort control (F-008) are impossible to persist across app restarts. Defect C.11 identifies the absence of a first-class profile entity as a major gap. Defects D.14-18 show model selection is dead code with no backing persistence. Defects E.19-20 confirm reasoning-effort is entirely absent. A separate entity avoids polluting the secure-storage `ServerConfig` with UX preferences and keeps the data-layer concerns cleanly separated.
**Consequences:**
- A new Isar collection `HermesProfile` must be created with schema migration (add collection on first access)
- `ServerConfig` continues to hold connection/auth fields in secure storage; a 1:1 foreign key (serverId) links `HermesProfile` to `ServerConfig`
- Chat provider (`chat_provider.dart`) reads `defaultModelId` and `reasoningEffort` from the active `HermesProfile` instead of hardcoding `'hermes-default'`
- Settings screen wires `defaultModelProvider` to the active profile's `defaultModelId` field
- Task form model field binds to the same profile-bound model selector
- Profile switching must invalidate cached profile state and re-read settings
**Cross-references:** GOAL_RC6 defects C.11, D.14-18, E.19-20. PRD features F-001 (Server Connection — multiple server profiles), F-002 (Chat — model selection), F-008 (Settings — model preference, profile switching).

### ADR-011: FLAG_SECURE Removal — Permanent
**Date:** 2026-07-15
**Status:** ACCEPTED (owner-explicitly-confirmed)
**Decision:** Remove all instances of `WindowManager.LayoutParams.FLAG_SECURE` from `android/app/src/main/kotlin/com/jahfali/hermex_android/MainActivity.kt`. This flag is currently applied in three lifecycle methods: `onCreate`, `onResume`, and `onWindowFocusChanged`. All three are to be removed fully and permanently.
**Rationale:** FLAG_SECURE blocks screenshots and screen recording at the Android OS level. While this is appropriate for banking or DRM-protected apps, Hermex Android is a chat client for a locally-running Hermes Agent API Server — there is no sensitive data requiring OS-level screen-capture prevention. The flag interferes with normal Android usage: screenshots for sharing, screen recording for debugging, and accessibility overlays. This flag was previously reinstated by the swarm against an earlier removal directive — recording this as a formal ADR prevents silent reversal in future commits. Defect G.25 in GOAL_RC6 identifies this as the specific item to remediate.
**Consequences:**
- `MainActivity.kt` loses three `window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, ...)` calls
- Users regain the ability to take screenshots and record their screen within the app
- Zero-trust auditor must verify no FLAG_SECURE remnants remain (`grep -rn "FLAG_SECURE" android/` → 0 matches)
- Any future attempt to re-add FLAG_SECURE must produce a new ADR referencing and explicitly overturning this one
**Cross-references:** GOAL_RC6 defect G.25. Exit criteria: `grep -rn "FLAG_SECURE" android/` → 0 matches.
