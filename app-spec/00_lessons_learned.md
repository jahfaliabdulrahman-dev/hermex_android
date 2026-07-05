# 00 — Lessons Learned

> Initiated: 2026-07-04
> Last Updated: 2026-07-06
> Project: hermex_android
> Version: 1.4.0

## 2026-07-04 — Project Initiation
- Decided Flutter over native Android (single codebase, existing expertise)
- Direct API Server connection (no hermes-webui)
- Triple Chinese MoA for swarm profiles

---

## 2026-07-05 — MVP Implementation (8 Features)

### LL-001: Server Connection — Static utility methods enable testability
- **Date:** 2026-07-05
- **Stage:** Implementation (Phase 2)
- **Files Affected:** lib/features/connection/
- **Lesson:** Static `isLocalNetwork()` on ServerRepository and ConnectionState renamed to ServerConnectionState to avoid Flutter SDK naming conflict.
- **Root Cause:** Flutter framework exports a `ConnectionState` enum; using the same name in app code caused ambiguous imports.
- **Prevention Rule:** Always search for existing Flutter/Dart symbols before naming classes. Prefer domain-specific prefixes.
- **Linked Decision ID:** N/A (implementation-level pattern)

### LL-002: SSE Streaming — Raw HttpClient over third-party SSE libraries
- **Date:** 2026-07-05
- **Stage:** Implementation (Phase 2)
- **Files Affected:** lib/core/api/sse_client.dart, lib/features/chat/
- **Lesson:** Custom SSE parser using `dart:io HttpClient` proved more reliable than immature Flutter SSE packages; manual SSE parsing (`data: {...}\n\n`) is straightforward.
- **Root Cause:** Flutter SSE library ecosystem immature — no production-ready package for raw SSE streaming.
- **Prevention Rule:** For non-mainstream protocols, prefer custom `dart:io` implementations over unproven third-party packages. Validate with integration tests.
- **Linked Decision ID:** ADR-001 (consequence noted)

### LL-003: Riverpod Provider Hygiene — Notifier vs AutoDisposeNotifier
- **Date:** 2026-07-05
- **Stage:** Implementation (Phase 2)
- **Files Affected:** lib/features/tasks/providers/task_provider.dart
- **Lesson:** `TaskListNotifier` extends `Notifier` (not `AutoDisposeNotifier`) per DEC-034 rule 2 — providers that hold server-fetched data must survive tab switches and should not auto-dispose.
- **Root Cause:** AutoDisposeNotifier discards state when the listening widget is removed from the tree; tab navigation causes rebuilds that would lose cached task/session data.
- **Prevention Rule:** Only use `AutoDisposeNotifier` for transient UI state (form data, search queries). Use `Notifier` for data fetched from the server.
- **Linked Decision ID:** DEC-034

### LL-004: Duplicate Tap Prevention — isBusy state flag
- **Date:** 2026-07-05
- **Stage:** Implementation (Phase 2)
- **Files Affected:** lib/features/tasks/providers/task_provider.dart, lib/features/chat/providers/chat_provider.dart
- **Lesson:** A simple `isBusy` boolean flag in provider state prevents duplicate network requests from rapid double-taps more reliably than widget-level debouncing.
- **Root Cause:** Widget-level debounce timers can be bypassed by rapid state changes; provider-level `isBusy` flag is atomic and shared across all listeners.
- **Prevention Rule:** Always guard mutation actions (send, delete, run-now) with an atomic `isBusy` check at the provider/notifier level.
- **Linked Decision ID:** N/A (implementation pattern)

### LL-005: GoRouter Route Ordering — Static paths before parameterized
- **Date:** 2026-07-05
- **Stage:** Implementation (Phase 2)
- **Files Affected:** lib/core/router/app_router.dart
- **Lesson:** GoRouter evaluates routes in order; `/tasks/new` must be declared BEFORE `/tasks/:id` to prevent "new" being captured as an ID parameter.
- **Root Cause:** GoRouter matches the first route whose pattern fits; `:id` matches any segment including "new".
- **Prevention Rule:** Always define static sub-routes before parameterized ones. Document this ordering constraint in router comments.
- **Linked Decision ID:** N/A (pattern)

### LL-006: Repository Null-Safety — Accept nullable ApiClient with safe defaults
- **Date:** 2026-07-05
- **Stage:** Implementation (Phase 2)
- **Files Affected:** lib/features/skills/data/skills_repository.dart, lib/features/workspace/data/workspace_repository.dart
- **Lesson:** Repositories that accept nullable `ApiClient` and return safe defaults (empty list) when no server is connected prevent null-check proliferation in providers.
- **Root Cause:** Providers may be read before a server connection is established; nullable ApiClient with graceful degradation avoids runtime null errors.
- **Prevention Rule:** All repositories should accept nullable dependencies and return safe defaults (empty list, null, cached data) when dependencies are unavailable.
- **Linked Decision ID:** N/A (pattern)

### LL-007: Provider Invalidation — Widget layer, not provider internals
- **Date:** 2026-07-05
- **Stage:** Implementation (Phase 2)
- **Files Affected:** lib/features/workspace/providers/workspace_provider.dart
- **Lesson:** `WorkspaceBrowserNotifier` does NOT call `ref.invalidate` internally — widget layer handles provider invalidation. Internal invalidation causes circular dependency chains in tests.
- **Root Cause:** Calling `ref.invalidate` from within a provider's own method creates a circular dependency that breaks Riverpod's dependency graph.
- **Prevention Rule:** Providers should never invalidate themselves or their parent providers. Invalidation belongs in the widget layer or in dedicated controller providers.
- **Linked Decision ID:** N/A (pattern)

### LL-008: Optimistic UI for Read-Only Toggle — Skills enable/disable
- **Date:** 2026-07-05
- **Stage:** Implementation (Phase 2)
- **Files Affected:** lib/features/skills/providers/skills_provider.dart
- **Lesson:** Skills toggle is optimistic local-only — no server-side mutation API defined. Toggle updates UI state immediately without waiting for server confirmation.
- **Root Cause:** Hermes Agent API Server `GET /v1/skills` returns skill data but no `PATCH /v1/skills/{name}` endpoint exists for toggling.
- **Prevention Rule:** When the backend lacks a mutation endpoint, implement optimistic local UI only and document the limitation clearly in code comments and spec.
- **Linked Decision ID:** N/A (API limitation)

### LL-009: Async API Client Resolution — SecureStorage requires async init
- **Date:** 2026-07-05
- **Stage:** Implementation (Phase 2)
- **Files Affected:** lib/core/providers/api_client_provider.dart
- **Lesson:** API client provider uses async resolution because the API key must be read from `flutter_secure_storage` which is asynchronous.
- **Root Cause:** `flutter_secure_storage` operations are inherently async; the ApiClient cannot be constructed synchronously.
- **Prevention Rule:** Any provider that depends on secure storage values must use `FutureProvider` or `AsyncNotifierProvider`. Never cache API keys in synchronous memory.
- **Linked Decision ID:** N/A (constraint of flutter_secure_storage)

### LL-010: Spec-Implementation Gap — API contract missing endpoints
- **Date:** 2026-07-05
- **Stage:** Implementation (Phase 2)
- **Files Affected:** app-spec/06_api_contract.md, lib/core/api/endpoints.dart
- **Lesson:** Implementation added `/v1/memory`, `/v1/insights`, `/v1/workspace` endpoints for F-006 and F-007, but 06_api_contract.md was never updated — spec drift detected during audit.
- **Root Cause:** Feature implementers added endpoints without back-propagating to the API contract spec.
- **Prevention Rule:** Any new API endpoint added during implementation MUST trigger a spec update task for the Documentation Steward.
- **Linked Decision ID:** N/A (process gap)

### LL-011: Duplicate Endpoints File — Two sources of API path constants
- **Date:** 2026-07-05
- **Stage:** Audit (Post-Implementation)
- **Files Affected:** lib/core/api/endpoints.dart, lib/core/constants/api_endpoints.dart
- **Lesson:** Two identical `ApiEndpoints` classes exist — one in `core/api/` and one in `core/constants/`. Both contain the same paths; only one should exist.
- **Root Cause:** Likely created by different implementers unaware of each other's work. Architecture spec (07) only specifies `core/api/endpoints.dart`.
- **Prevention Rule:** The 07_flutter_architecture.md file tree is the authoritative source for file locations. Any deviation requires a DEC and architecture spec update.
- **Linked Decision ID:** N/A (traceability defect)

### LL-012: Security Spec Coverage — 08_security_privacy.md is minimal
- **Date:** 2026-07-05
- **Stage:** Audit (Post-Implementation)
- **Files Affected:** app-soc/08_security_privacy.md, app-spec/18_zero_trust_red_team_audit.md
- **Lesson:** 08_security_privacy.md only covers 3 of 10 mandatory attack vectors from 18_zero_trust_red_team_audit.md. Vectors 4-10 (token replay, input injection, SSE poisoning, deep link, clipboard, background snapshot) have no documented mitigations.
- **Root Cause:** Security spec was authored early and never expanded as zero-trust audit requirements evolved.
- **Prevention Rule:** Every vector in 18_zero_trust_red_team_audit.md MUST have a corresponding mitigation section in 08_security_privacy.md. Cross-reference both files at audit time.
- **Linked Decision ID:** N/A (traceability defect — flagged for Lead Architect)

---

## 2026-07-05 — Process & Governance Lessons

### LL-013: Big Bang QA — QA must be phased alongside feature delivery
- **Date:** 2026-07-05
- **Stage:** Post-Mortem (Post-Implementation)
- **Source:** Sulaiman + Abdulrahman review
- **Issue:** Lead Architect decomposed project as: all 8 features → single QA phase at end. This "Big Bang Testing" pattern means defects discovered late have exponentially higher fix costs and risk cascading rework across already-completed features.
- **Root Cause:** Decomposition strategy treated QA as a final gate rather than a continuous phased gate. No rule in the Global Contract or Lead Architect's SOUL enforces phased testing.
- **Impact:** If QA found a fundamental issue (e.g., SSE streaming breaks on certain responses), ALL features depending on Chat would need rework — potentially F-003, F-004, F-005, F-006, F-007.
- **Severity:** 🔴 High — applies to ALL future projects, not just Hermex Android
- **Prevention Rule:** QA must be decomposed into phases matching feature delivery groups. Each phase must pass its QA gate before the next phase begins implementation. The sequence should follow: F-001 build → QA → ✅ → F-002+F-003 build → QA integration → ✅ → F-004+F-005+F-006 build → QA → ✅ → F-007+F-008 build → QA → ✅ → Final integration QA → Zero-Trust Audit → Release.
- **Governance Impact:** This rule must be added to `FLUTTER_GLOBAL_CONTRACT.md` (new rule: "No Big Bang QA — Phased Testing Mandatory") and `flutter-lead-architect/SOUL.md` (decomposition constraint).
- **Linked Decision ID:** N/A (process gap — discovered in post-mortem)

### LL-014: GitHub Repository Push — Release task must include git push
- **Date:** 2026-07-05
- **Stage:** Post-Mortem (Post-Implementation)
- **Source:** Sulaiman + Abdulrahman review
- **Issue:** `flutter-devops-release-engineer` completed RELEASE task (`t_31c01209`) with APK build config, signing, and branding — but NEVER initialized git or pushed the project to GitHub. The project existed only on the local machine with zero remote backup.
- **Root Cause:** The RELEASE task description did not explicitly require git initialization, remote setup, or push as deliverables. The DevOps profile executed only what was specified.
- **Impact:** Project was invisible to the outside world; no remote backup; Abdulrahman couldn't find the repo when searching GitHub. Required manual intervention to init git, commit, create repo, and push.
- **Severity:** 🟡 Medium — easily fixable but reveals a critical gap in the RELEASE task template
- **Prevention Rule:** All RELEASE tasks MUST include as mandatory deliverables: (1) `git init` if not already a repo, (2) `gh repo create` with description, (3) `git push` to remote. These must be in the task body, not left to the profile's discretion.
- **Governance Impact:** Update `flutter-devops-release-engineer/SOUL.md` to add git push as non-negotiable step in release checklist. Update `10_devops_release_observability.md` template to include git remote push in release gates.
- **Linked Decision ID:** N/A (process gap — discovered in post-mortem)

---

## Summary

| Category | Count |
|----------|-------|
| Architecture patterns | 5 (Notifier/AutoDispose, isBusy guard, route ordering, nullable repos, provider invalidation) |
| Implementation pitfalls | 3 (Flutter symbol conflicts, async API key, duplicate files) |
| Spec gaps found | 3 (API contract, security coverage, duplicate endpoints) |
| Process & governance gaps | 3 (Big Bang QA, missing git push, workspace verification) |
| **Total lessons** | **19 (LL-001 through LL-014, LL-017 through LL-021)** |

---

### LL-021 — Orchestrator Workspace Verification — File existence check before broadcast
- **Date:** 2026-07-06
- **Stage:** Post-Mortem (EPIC Recovery)
- **Source:** EPIC t_c7e1520f workspace misdirection
- **Issue:** As Lead Architect, I directed all 13 child tasks of the Hermex Android Recovery EPIC to `/Users/abdurrahmanjahfali/CarSah` — a completely different project (local-first Isar MVP for vehicle maintenance). Workers began executing against CarSah, reporting that target files didn't exist, before the error was detected by cross-referencing completed audit task `t_a0f8a7db` which used workspace `/Users/abdurrahmanjahfali/Projects/hermex_android`.
- **Root Cause:** The orchestrator assumed the workspace path based on recency of other projects, without verifying that ANY of the task bodies' target files actually existed at that path. No pre-broadcast validation gate existed. Additionally, `write_file` was used to append LL-021 to this file, which silently **overwrote all 163 previous lines** containing LL-001 through LL-014 — the file had to be recovered via `git checkout HEAD` and LL-021 re-appended via `cat >>`.
- **Impact:** 3 tasks falsely completed against wrong project (T1 widget test for CarSahApp, T4 deprecated no-op against CarSah's SDK, T10 156-line security diff to CarSah reverted). 5 tasks blocked with file-not-found errors. ~30 minutes lost redirecting and correcting. This lessons file was destroyed and had to be restored from git. 3 replacement tasks (T1-R, T4-R, T10-R) created with correct Hermex workspace.
- **Prevention Rule:** 1) Before broadcasting any workspace directive, the orchestrator MUST verify at least 2-3 target files exist at the proposed path via `ls`. 2) When appending to existing documentation files, use `cat >>` or `patch` — NEVER `write_file` which overwrites entire files. 3) Before any `write_file` call, re-read the target file completely to verify its current content.
- **Linked Decision ID:** N/A (orchestration governance — discovered in EPIC recovery)

---

## 2026-07-06 — Triple Chinese MoA Audit Lessons

### LL-017: Router Wiring Gap — Code exists but screens not wired
- **Date:** 2026-07-06
- **Stage:** Post-Mortem (MoA Audit)
- **Source:** Triple Chinese MoA analysis of Hermex Android
- **Issue:** `chat_screen.dart`, `workspace_screen.dart`, and `skills_screen.dart` were fully implemented with passing tests, but `app_router.dart` used `_placeholderScreen()` stubs instead of importing and wiring the real screens. The Traceability Matrix marked F-002, F-005, F-006 as "✅ Implemented" — but users could never reach these screens because they weren't connected to the router.
- **Root Cause:** No governance rule required Router Wiring as an acceptance gate. The Lead Architect wrote the router with stubs during early development and never updated them after State Engineer completed the implementations. No smoke test verified that each feature route renders the real screen.
- **Impact:** 3 of 8 features (37.5%) were effectively dead code — implemented but unreachable. The project's real completion rate was ~50%, not 100% as the Traceability Matrix claimed.
- **Prevention Rule:** Router Wiring = Acceptance Gate. No feature is DONE until its screen is imported and wired in `app_router.dart`. The Traceability Matrix must include a "Router Wired" column.
- **Linked Decision ID:** N/A (governance gap — discovered in MoA audit)

### LL-018: Missing ProviderScope in Widget Test — App renders without crashing FAILED
- **Date:** 2026-07-06
- **Stage:** Post-Mortem (MoA Audit)
- **Source:** Triple Chinese MoA analysis of Hermex Android
- **Issue:** `widget_test.dart` called `HermexApp()` directly without wrapping it in `ProviderScope`. The main `runApp()` in `main.dart` does wrap with `ProviderScope`, but the test did not. This caused the most basic smoke test to fail: "HermexApp renders without crashing — FAILED."
- **Root Cause:** No rule mandated that the smoke test be written FIRST (before feature implementation) or that it must mirror the exact widget tree from `main.dart`. Smoke test was likely written after features were complete, and the ProviderScope dependency was missed.
- **Impact:** 402 tests passed but the single most important test — "does the app even load?" — failed. This means no one could verify end-to-end functionality through automated tests.
- **Prevention Rule:** Smoke Test First. Every Flutter project MUST have `App renders without crashing` as the FIRST test, mirroring `main.dart`'s widget tree exactly (including ProviderScope). This test must pass before any feature implementation begins.
- **Linked Decision ID:** N/A (governance gap)

### LL-019: Empty Catch Blocks in Auth Path — Silent security failures
- **Date:** 2026-07-06
- **Stage:** Post-Mortem (MoA Audit)
- **Source:** Triple Chinese MoA analysis of Hermex Android
- **Issue:** `auth_manager.dart` contains two `catch (_) {}` blocks that silently swallow all exceptions from `flutter_secure_storage`. Combined with null assertions (`!`) in `certificate_pinner.dart`, this creates a compound risk: TLS pinning silently disabled + no auth error surfaced = potential MITM attack vector.
- **Root Cause:** Developer used empty catch blocks as a "quick fix" during development, intended to add proper error handling later. No linting rule or code review gate flagged them.
- **Impact:** Security-critical operations (auth, TLS) can fail silently with zero visibility. Combined failure scenario: secure storage fails → TLS pinning disabled → MITM attack on public WiFi → API token theft.
- **Prevention Rule:** Empty catch blocks are FORBIDDEN in security-critical paths (auth, TLS, storage, network). Minimum: log the error. Preferred: surface to user or fallback to safe state. Add linting rule: `avoid_empty_catch`.
- **Linked Decision ID:** N/A (code quality — discovered in MoA audit)

### LL-020: Stale Router After Feature Completion — No wiring verification gate
- **Date:** 2026-07-06
- **Stage:** Post-Mortem (MoA Audit)
- **Source:** Triple Chinese MoA analysis of Hermex Android
- **Issue:** The Kanban workflow treated "Feature Implementation" and "Router Wiring" as a single implicit task. The State Engineer implemented features in `lib/features/` but the router in `lib/core/router/` was never updated. No Kanban task existed for "Wire Feature X to Router."
- **Root Cause:** The Kanban decomposition model assumed that creating feature files automatically meant they were wired. Router wiring was not a separate, explicit task in the workflow.
- **Impact:** Systematic risk — any future project using this workflow would have the same gap. Features get built but never connected.
- **Prevention Rule:** Every Feature implementation task MUST have a paired "Router Wiring" subtask. The Kanban board must include a "ROUTER_WIRING" verification column or the Definition of Done must explicitly include "Screen is reachable via router navigation."
- **Linked Decision ID:** N/A (process gap)
