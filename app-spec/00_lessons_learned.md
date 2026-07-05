# 00 — Lessons Learned

> Initiated: 2026-07-04
> Last Updated: 2026-07-05
> Project: hermex_android
> Version: 1.3.0

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
| Process & governance gaps | 2 (Big Bang QA, missing git push) |
| **Total lessons** | **14 (LL-001 through LL-014)** |
