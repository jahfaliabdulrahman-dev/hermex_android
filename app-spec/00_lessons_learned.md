# 00 — Lessons Learned

> Initiated: 2026-07-04
> Last Updated: 2026-07-11
> Project: hermex_android
> Version: 1.5.0

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
| Operational bug recovery | 3 (LL-022 Silent API Key Redaction, LL-023 Fake Connection State, LL-024–LL-029 Android) |
| Governance failures | 1 (LL-030 Orchestrator Direct Code Execution) |
| **Total lessons** | **28 (LL-001 through LL-030)** |

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

---

## 2026-07-06 — Android Build Failures & Skill Remediation

### LL-024: Namespace Mismatch — AndroidManifest resolves to wrong class
- **Date:** 2026-07-06
- **Stage:** Release (first device install)
- **Source:** Physical Android device install test
- **Issue:** `namespace = "com.hermex.android"` in `build.gradle.kts` but `MainActivity.kt` declared `package com.jahfali.hermex_android`. Android resolved `android:name=".MainActivity"` relative to namespace → `com.hermex.android.MainActivity` → `ClassNotFoundException` → crash before splash screen.
- **Root Cause:** 9-profile swarm generated code without coordination. DevOps Engineer set namespace, State Engineer set Kotlin package — no profile owned the end-to-end Android build correctness.
- **Impact:** App "لم يفتح نهائيا" (never opened). User saw nothing. Critical first-impression failure.
- **Prevention Rule:** Android Verification Gate §1 — namespace in build.gradle.kts MUST equal MainActivity.kt package. Automated script verifies before every release.
- **Linked Decision ID:** N/A (build configuration gap)

### LL-025: Isar + ProGuard/R8 Incompatibility
- **Date:** 2026-07-06
- **Stage:** Release (discovered during LL-024 investigation)
- **Source:** Code audit
- **Issue:** `isMinifyEnabled = true` in release build type strips Isar adapter classes (CachedSessionAdapter, etc.) because they are loaded reflectively, not directly referenced in Java/Kotlin code. Even if the namespace was correct, the app would crash on `Isar.open()`.
- **Root Cause:** No profile SOUL or spec file documented the Isar + ProGuard incompatibility. `android/skills` official docs confirm this pattern.
- **Impact:** Compound failure — two independent crashes, either one fatal.
- **Prevention Rule:** Android Verification Gate §2 — if `isar:` in `pubspec.yaml`, `isMinifyEnabled` MUST be `false`. Automated script verifies before every release.
- **Linked Decision ID:** N/A (build configuration gap)

### LL-026: Android Build Knowledge Gap — No official sources in swarm
- **Date:** 2026-07-06
- **Stage:** Post-Mortem (Root Cause Analysis)
- **Source:** Comprehensive audit of all 9 Flutter profiles + Spec Pack
- **Issue:** Zero profiles had Android build knowledge. Words `namespace`, `ProGuard`, `applicationId` appeared NOWHERE in any SOUL file. Spec File 10 (DevOps) was 19 lines — no Android build configuration checklist.
- **Root Cause:** Swarm was designed for Dart/Flutter expertise only. Android native build system was an implicit blind spot — everyone assumed "someone else handles it."
- **Impact:** Systemic risk for ALL future Flutter projects.
- **Prevention Rule — 3 New Skills Created from Official Sources:**
  1. `android-build-system` ← github.com/android/skills (Google AI-optimized) + developer.android.com
  2. `flutter-android-deployment` ← docs.flutter.dev/deployment/android
  3. `android-verification-gate` ← custom (LL-024 enforcement)
  
  These skills are MANDATORY for flutter-devops-release-engineer and flutter-lead-architect. Updated SOULs to enforce loading.
- **Linked Decision ID:** N/A (competency gap remediation)

### LL-027: Android Cleartext HTTP Blocked — network_security_config whitelist too narrow
- **Date:** 2026-07-06
- **Stage:** Release (first real-device connection test)
- **Source:** User tested app with real Hermes Agent server on LAN
- **Issue:** `network_security_config.xml` allowed cleartext HTTP only for hardcoded IPs (192.168.1.1, 192.168.0.1, etc.). User's server at `192.168.8.80` was NOT on the list. Android silently dropped all HTTP connections to any IP not in the domain-config whitelist. The server returned HTTP 200 via curl from Mac — proving server/firewall/port were all correct. The app timed out after exactly 10 seconds (matching the Dart `connectTimeout`) with zero network activity reaching the server.
- **Root Cause:** The domain-config whitelist in `network_security_config.xml` was designed during development with hardcoded common IPs (192.168.1.1, 192.168.0.1, 192.168.1.100, 10.0.0.1, etc.). Android's `<domain>` element does NOT support CIDR notation, so the list had to be exhaustive. Any IP not explicitly listed was blocked at the OS level before Dio/Dart ever saw the request.
- **Impact:** 2+ hours of debugging across macOS firewall, Hermes config paths, port binding, proxy attempts, and gateway restarts — none of which were the actual problem. The bug was in the app's Android configuration, 4 layers removed from where we were debugging.
- **Fix:** Changed `<base-config cleartextTrafficPermitted="false">` to `true`. Dart-level validation (`_validateUrl()` → `isLocalNetwork()`) already restricts HTTP to RFC 1918 private IPs, so this doesn't weaken security — it just removes an overly restrictive OS-level duplicate check.
- **Prevention Rule:** 1) `network_security_config.xml` MUST use `cleartextTrafficPermitted="true"` in base-config for local-server apps. 2) The `android-preflight.sh` script MUST verify the base-config allows cleartext. 3) If domain-config whitelist is used, it MUST include a comment warning that any IP not listed will be silently blocked by Android.
- **Linked Decision ID:** N/A (Android network policy gap)

### LL-028: macOS Firewall Blocks Hermes Python Binary
- **Date:** 2026-07-06
- **Stage:** Connection debugging
- **Source:** User's Mac refused incoming connections to Python server despite `host: 0.0.0.0`
- **Issue:** macOS Application Firewall (`socketfilterfw`) allows specific binaries. The Hermes gateway runs Python 3.11 from uv's cache path (`~/.local/share/uv/python/cpython-3.11.15-macos-aarch64-none/bin/python3.11`). This path was NOT in the firewall allow list, even though `/usr/bin/python3` and `/opt/homebrew/.../python3.12` were. Incoming connections were silently dropped.
- **Fix:** `sudo socketfilterfw --add <hermes-python-path>` + `sudo socketfilterfw --unblockapp <path>`
- **Prevention Rule:** After any Hermes Python upgrade or venv recreation, verify the new Python binary is in the macOS firewall allow list. Add to the `android-preflight.sh` or a separate macOS setup script.

### LL-029: Duplicate User Messages — State Mutation Before History Capture
- **Date:** 2026-07-06
- **Stage:** First chat test after successful connection
- **Source:** User sent first message "السلام عليكم" — app crashed with API error
- **Issue:** `ChatNotifier.sendMessage()` added the user message to `state.messages` (line 254) BEFORE calling `_buildHistory()` (line 260). Since `_buildHistory()` reads from `state.messages`, the history included the just-added user message. Then `chat_repository.dart` added the same message AGAIN explicitly: `messages.add({'role': 'user', 'content': message})`. Result: two consecutive `role: user` messages in the API request. Hermes API enforces strict user/assistant alternation and rejected with "Invalid argument (string): Contains invalid characters."
- **Root Cause:** Mutation order bug — mutable state (`state.messages`) was updated before the snapshot (`_buildHistory()`) was taken. This is a classic React/Riverpod anti-pattern: reading derived state after mutating the source.
- **Fix:** Moved `final history = _buildHistory()` to BEFORE `state = state.copyWith(messages: [...state.messages, userMessage, agentMessage])`. History now contains only previous messages.
- **Prevention Rule:** 1) Never call a history/snapshot builder AFTER mutating the state it reads from. 2) Add a unit test for `sendMessage` that verifies exactly one user message appears in the API request body. 3) Consider a lint rule or PR checklist item: "Does any state.copyWith() precede a _buildHistory()-style snapshot?"
- **Bug Class:** NEW — this is a Flutter/Riverpod state management bug, NOT an Android knowledge gap. Different from LL-024/025/027 (which were Android build/config issues). Requires Dart-level testing, not Android-level gates.
- **Linked Decision ID:** N/A (state management pattern)

---

## 2026-07-07 — Operational Bug Recovery Session

### LL-022: Silent API Key Redaction — `***` literal replaced variable
- **Date:** 2026-07-07
- **Stage:** Production Bug Recovery
- **Source:** Abdulrahman report — "Agent Data (Skills, Memory, Insight) لا تعمل"
- **Issue:** Two files (`api_client_provider.dart:73`, `connection_screen.dart:226`) contained `apiKey: ***` as a literal string instead of the `apiKey` variable. This redaction artifact — likely from the swarm's SOUL-level security sanitization — silently broke ALL API-dependent features. Every request carried the literal HTTP header `Authorization: Bearer ***`.
- **Root Cause:** The MoA swarm's security layer replaced actual API key values with `***` during output redaction. These redacted outputs were then treated as source code and committed. No human or automated gate detected that `***` is not valid Dart syntax referencing a variable named `apiKey`. The compiler does not flag this — `***` is valid Dart (three `*` operators).
- **Impact:** Skills, Memory, Insights, Chat streaming, and any feature relying on `ApiClient` failed silently. Health endpoint returned 401 but error messages were not surfaced properly. The app appeared functional but every API call received "Unauthorized."
- **Prevention Rule (PERMANENT — GOV-005):** No commit may pass if `grep -rn "apiKey: \*\*\*" lib/` or `grep -rn "api_key: \*\*\*" lib/` returns matches. These are SOUL-redaction artifacts that MUST be reverted to actual variable names before commit. Add to CI pre-commit hook and governance rules.
- **Governance Impact:** Added to `00_swarm_operating_playbook.md` as permanent rule under §Governance.
- **Linked Decision ID:** N/A (security sanitization defect)

### LL-023: Fake Connection State — selectServer declared connected without health check
- **Date:** 2026-07-07
- **Stage:** Production Bug Recovery
- **Source:** Abdulrahman report — "السيرفرات المحفوظة لا تدخلني على السيرفر"
- **Issue:** `ConnectionNotifier.selectServer()` set `status: ConnectionStatus.connected` immediately after `setActive(serverId)` — without retrieving the stored API key or performing a health check against the server. ConnectionScreen's listener used a flag `_hasAttemptedConnection` that only triggered after manual `_handleConnect()`, so saved server selection never auto-navigated to chat.
- **Root Cause:** `selectServer` was designed as a state-local operation ("mark this server as active") but its name (`selectServer`) and state flag (`connected`) implied full connection functionality. No health check, no key retrieval, no auto-navigation. Two separate bugs compounded: (1) the fake connection, (2) the auto-nav gate.
- **Prevention Rule (PERMANENT):** Any method that transitions status to `ConnectionStatus.connected` MUST: (a) retrieve the API key, (b) perform a health check, (c) only transition on success. Never use `connected` as a local-only state — it MUST represent verified server reachability.
- **Governance Impact:** Connection lifecycle is a security boundary. Mark as invariant in architecture spec.
- **Linked Decision ID:** N/A

### LL-030: Orchestrator Direct Code Execution — Bypassed Kanban, Documentation, Audit, Review
- **Date:** 2026-07-07
- **Stage:** Governance Failure
- **Source:** Abdulrahman warning — "هذا تحذير شديد اللهجة لك"
- **Issue:** The Lead Architect executed 6 code changes across 7 files directly — bypassing the entire governance system. No Kanban tasks were created. No specification was consulted. No external review was requested. No documentation was written before or during execution. No audit was performed. No push to GitHub was attempted. The work produced correct code (404 tests, 0 analyze issues) but deprived the project of traceability, institutional memory, and quality gates.
- **Six Governance Violations in One Session:**
  1. No Kanban task created for any of the 3 bug fixes
  2. Implementer = Reviewer (same agent)
  3. No external audit before declaring "done"
  4. No documentation written during execution
  5. No decision log entry for architectural changes
  6. No push to GitHub for remote backup
- **Root Cause:** The orchestrator privileged speed over system. The user's initial request to bypass Kanban was accepted without pushback. Accumulated false confidence from "3 MoA references agree" statements that had no external verification.
- **Prevention Rule (PERMANENT — GOV-001):** The Lead Architect shall NEVER write application code. This profile's role is orchestration, approval, conflict resolution, architectural integrity, traceability, and final technical governance (§1 SOUL identity). Code changes flow through: Kanban task → specialized agent → QA → audit → deployment. The orchestrator verifies, never implements.
- **Governance Impact:** Added to `00_swarm_operating_playbook.md` §Governance as immutable rule GOV-001. This rule is PERMANENT and shall not be waived for speed, urgency, or user request.
- **Linked Decision ID:** N/A (sovereign governance — user directive)

---

## 2026-07-11 — RC4 Documentation & Release Prep

### LL-031: Premature EPIC Closure — Parent completed while child tasks still running
- **Date:** 2026-07-11
- **Stage:** RC4 Coordination
- **Files Affected:** Kanban task `t_31a0453e`
- **Lesson:** An EPIC-level orchestrator task (`t_31a0453e`) was marked "done" while its dispatched child tasks were still running. Downstream workers that depended on the EPIC's output were misled into starting work on stale or incomplete preconditions.
- **Root Cause:** The orchestrator's completion gate only checked whether it had dispatched all child tasks — not whether all children had completed successfully. The kanban dependency model relies on explicit parent→child linkages, but the orchestrator's own state transition had no "all children resolved" verification.
- **Prevention Rule:** An orchestrator task MUST NOT transition to "done" until every child task it created has itself reached a terminal state (done/blocked/cancelled). Add a pre-completion gate that queries child task states and blocks completion if any remain running.
- **Linked Decision ID:** N/A (process gap)

### LL-032: Test Threshold Mismatch — Declared 469 vs actual 452
- **Date:** 2026-07-11
- **Stage:** RC4 Verification
- **Files Affected:** Various test files, `00_lessons_learned.md`, Kanban task descriptions
- **Lesson:** A stated "469 tests passing" was inherited from a prior session's environment. The actual count was 452 in the current workspace (before RC4 fixes). Publishing an incorrect threshold created confusion during verification gates: reviewers expected 469 but got 452, triggering unnecessary investigation into "missing" tests.
- **Root Cause:** The test count was recorded as a prose constant in task bodies and summaries without re-verifying at handoff. The count drifted between environments (different feature branches, partial checkouts, cached build artifacts) but was never re-computed from `flutter test` at the start of each worker session.
- **Prevention Rule:** Every task that mentions a test count MUST run `flutter test` at the start of the session to establish the true baseline. Never reuse a test count from a parent task, summary, or prior session without re-verification.
- **Linked Decision ID:** N/A (process gap)

### LL-033: Theme Crisis False Alarm — Stale Workspace Artifacts
- **Date:** 2026-07-11
- **Stage:** RC4 Theme Verification
- **Files Affected:** `lib/core/theme/`
- **Lesson:** A WIP commit (`0a2c5e6`) on the `epic/rc4-polish` branch contained 32 analyzer errors and 9 test failures from a failed theme migration attempt. A worker inspecting the branch saw these artifact errors and raised a "theme crisis" alarm. The actual clean state was at `8aec1db` (0 errors, 484/484 pass) — the WIP commit was an abandoned save point from a different agent session, not the current working state.
- **Root Cause:** The branch contained orphaned WIP commits from a prior worker that did a force-push or rebase cleanup without removing the stale commit. No branch hygiene rule prevented stale/incomplete commits from accumulating on shared branches.
- **Prevention Rule:** Before starting work on a shared branch, run `git log --oneline -5` and verify the HEAD commit matches the expected baseline. If stale WIP commits are present, either (a) `git reset --hard` to the last clean commit, or (b) cherry-pick only completed fixes and abandon the WIP commit. Document the baseline commit ID in the task body.
- **Linked Decision ID:** N/A (branch hygiene)

---

## 2026-07-11 — RC5 Regression Fixes & Governance

### LL-038: Incomplete fix marked done — theme tokens defined but not wired
- **Date:** 2026-07-11
- **Stage:** RC5 Regression Fixes
- **Files Affected:** `lib/core/theme/`, `app-spec/04_ui_design_system.md`
- **Lesson:** Theme color tokens for light mode were defined in `HermesColors` constants and `04_ui_design_system.md` §1.5, but `AppTheme.buildLight()` was never wired into the widget tree — making the entire light theme unreachable despite all declarations being marked complete.
- **Root Cause:** The prior agent defined tokens and spec sections as "done" without verifying the end-to-end wiring: `ThemeData` → `MaterialApp.themeMode` → `ThemeMode.light`. No test verified that swapping to light theme actually renders light colors.
- **Prevention Rule:** A spec token definition is NOT "done" until the widget tree consumes it. Define a test that toggles `ThemeMode.light` and asserts at least one visible element uses a light-mode color. Document wire-up as a separate AC in the feature task.
- **Linked Decision ID:** DEC-045

### LL-039: Release published before gates passed — build gate bypass
- **Date:** 2026-07-11
- **Stage:** RC5 Post-Mortem
- **Files Affected:** `CHANGELOG.md`, Release process, Kanban release tasks
- **Lesson:** The RC4 release was published (CHANGELOG written, APK built, branch pushed) before all DEC-045 spec sync gates had passed. The build gate was bypassed, leading to an RC4 takedown and forcing an RC5 regression release.
- **Root Cause:** No hard gate prevented `flutter build apk` from executing when the spec sync gate was still RED. The Kanban pipeline allowed the RELEASE task to claim readiness without awaiting the stage-gate signal.
- **Prevention Rule:** The RELEASE task MUST check DEC-045_GATE status before running `flutter build apk`. If the gate is RED, the build is blocked. Add a pre-build verification step to the DevOps release workflow.
- **Linked Decision ID:** DEC-045

### LL-040: Gate tasks marked done without actual validation
- **Date:** 2026-07-11
- **Stage:** RC5 Post-Mortem
- **Files Affected:** Kanban task descriptions, verification task bodies
- **Lesson:** Gate tasks (verification, QA, audit) were marked "done" on the Kanban board without actual validation — the worker ticked the completion checkbox without running the specified checks or producing verifiable evidence.
- **Root Cause:** No enforcement mechanism required gate tasks to output verifiable evidence (e.g., test logs, diff output, health check results) before transitioning to done. The Kanban board had no "results required" column rule.
- **Prevention Rule:** Gate tasks MUST include a "Results / Evidence" field in their body that MUST be populated with verifiable output (test run log, screenshot, diff) before the task can be completed. Automated guard: a gate task with empty evidence field cannot transition to "done."
- **Linked Decision ID:** DEC-045

### LL-041: EPIC child tasks with `parents: [EPIC_ID]` cause dispatch deadlock
- **Date:** 2026-07-11
- **Stage:** RC5 Coordination
- **Files Affected:** Kanban dispatch logic, EPIC task definitions
- **Lesson:** Creating EPIC child tasks with `parents: [EPIC_ID]` caused a dispatch deadlock — the EPIC card could not reach "done" until ALL child tasks completed, but the child tasks had the EPIC as a parent dependency, creating a circular dependency that stopped the Kanban pipeline entirely.
- **Root Cause:** The Kanban dependency model interprets `parents: [EPIC_ID]` as "wait for EPIC to finish first." But the EPIC card itself cannot finish until its children are done. This creates a deadlock: children wait for EPIC, EPIC waits for children — neither can transition.
- **Prevention Rule:** NEVER set `parents: [EPIC_ID]` on sub-tasks of an EPIC. EPIC cards are decomposition markers, not actual dependencies. Child tasks should either (a) have no `parents`, or (b) depend on a single sequential predecessor task within the same EPIC. The EPIC card's own state transitions are managed by the orchestrator, not the dependency graph.
- **Linked Decision ID:** N/A (Kanban usage pattern)
