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
