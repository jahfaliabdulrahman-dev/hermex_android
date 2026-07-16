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

## RC6 Remediation Decisions (2026-07-15)

### ADR-010: Hermes Profile as First-Class Entity with Per-Profile Model + Reasoning-Effort
**Date:** 2026-07-15
**Decision:** Introduce `HermesProfile` as a first-class Isar entity — replacing the flat `ServerConfig` model — carrying per-profile `defaultModelId` and `reasoningEffort` fields. Profiles are owner-approved as the canonical unit of server identity.
**Rationale:** Current `ServerConfig` (defect C.11) only stores id/name/url/isDefault/lastConnected — no model or reasoning-effort settings. The model selection UI (defects D.14-D.18) is dead code with no data model to bind to. Reasoning-effort control (defects E.19-E.20) has zero plumbing. A first-class `HermesProfile` entity is the architectural prerequisite for: reactive profile switching (C.12), model selection wired end-to-end (D.14-D.18), reasoning-effort/thinking control (E.19-E.20), and the orphaned "Default Model" setting (D.17). This is the single data-model change that unlocks 12 of the 26 RC6 defects. Owner explicitly approved this direction — do not revert to flat ServerConfig.
**Consequences:**
- Requires Isar schema migration from `ServerConfig` to `HermesProfile` (Backend/DB Architect — Phase 1a)
- Every screen that reads server identity (Chat, Sessions, Tasks, Settings) must bind to the new entity
- `resolvedApiClientProvider` must derive its active server from `HermesProfile.isActive`
- Per-profile model/reasoning-effort defaults travel with the profile, not global app state
- This decision is IRREVERSIBLE within RC6 — reverting to flat ServerConfig would regress 12 defects
**References:** C.11, D.14-D.18, E.19-E.20, PRD F-001 (Multiple server profiles), PRD F-008 (Profile switching, Model preference)

### ADR-011: FLAG_SECURE Permanent Removal from MainActivity.kt
**Date:** 2026-07-15
**Decision:** Remove `FLAG_SECURE` from all three locations in `MainActivity.kt` (`onCreate`, `onResume`, `onWindowFocusChanged`). This removal is permanent and owner-confirmed — do not re-add.
**Rationale:** `FLAG_SECURE` blocks screenshots and screen recording across the entire app. The owner has explicitly confirmed this should be removed, permanently, from all locations. FLAG_SECURE was previously reinstated by the swarm against an earlier removal directive — this ADR serves as the authoritative record that the removal is intentional and must not be silently reversed. Hermex Android is a client for self-hosted agents; users own their data and should be able to capture their own screens. Security-sensitive content (API keys) is already protected at the OS level via `flutter_secure_storage` and never displayed in plaintext in the UI.
**Consequences:**
- Users can take screenshots and screen-record the app
- Exit criterion: `grep -rn "FLAG_SECURE" android/` must return 0 matches
- If a future security requirement demands screenshot blocking, it must be scoped to specific screens (e.g., settings/API key view) via a platform channel toggle, NOT a global window flag — and must go through a new ADR with owner approval
- This ADR supersedes any prior implicit assumption that FLAG_SECURE should be present
**References:** G.25, VEC-001 (credential leakage already mitigated by flutter_secure_storage)

---

## RC6 Process Integrity Decision (2026-07-16)

### ADR-012: Gate Rescan Integrity — Re-test SPECIFIC Rejected Findings (H.26)
**Date:** 2026-07-16
**Decision:** Any security/QA gate that was previously REJECTED must, when re-scanned for PASS, explicitly re-test the SPECIFIC findings that caused the prior REJECT — with verifiable evidence attached. Re-verifying unrelated already-passing items does NOT constitute a valid re-scan.
**Rationale:** RC5 Gate2 security audit REJECTED the release over AUD-RC5-001 (raw exception leakage to UI) and AUD-RC5-002. A same-day "Gate4 rescan" declared PASS by only re-verifying older already-passing items (FLAG_SECURE, keystore, cleartext, fonts) — the report never mentioned or retested AUD-RC5-001/002. RC6 investigation found AUD-RC5-001 still live in 8+ code sites across session_provider.dart, chat_provider.dart, and stream_provider.dart, proving the rescan was a false pass. This pattern mirrors LL-038 (theme tokens defined but not wired), LL-039 (release published before gates passed), and LL-040 (gate tasks marked done without validation) — all share the root cause of checking surface-level readiness without verifying the deep condition.
**Consequences:**
- All gate re-scans MUST include a "Prior REJECT Findings" section listing every finding from the previous rejection, with a status and evidence link for each.
- Gate tasks MUST include a "Results / Evidence" field populated with verifiable output (grep output, test run log, screenshot) before transitioning to "done" (codifies LL-040 as a hard rule).
- The Lead Architect MUST independently verify gate evidence before closing any EPIC that had a prior REJECT — cannot delegate this check.
- This ADR is retroactive: any prior gate PASS on a task that was previously REJECTED is now considered PROVISIONAL until the specific rejected findings are re-verified with evidence.
**References:** H.26, AUD-RC5-001, AUD-RC5-002, LL-029 (duplicate messages — state mutation bug), LL-038 (incomplete fix marked done), LL-039 (release before gates), LL-040 (gate tasks without validation evidence), GOAL_RC6_COMPREHENSIVE_REMEDIATION.md §H
