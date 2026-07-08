# ARCHITECTURE REVIEW — Cross-Cutting Auth Key Fix + Endpoint Feature-Gating
# hermex_android | Date: 2026-07-08
# Lead Architect: Triple Chinese MoA (deepseek-v4-pro + qwen3.7-max + glm-5.2)
# Task: t_62425b71

---

## 1. Executive Summary

Two cross-cutting architectural anti-patterns threaten the app's security posture and user experience:

1. **Auth Key Bypass Anti-Pattern (HIGH/SECURITY):** `chat_provider.dart` and `task_provider.dart` instantiate `AuthManager` + `ApiClient` directly, bypassing the centralized `resolvedApiClientProvider`. This silently disables certificate pinning (AUD-001/VEC-002) for chat and tasks — the two most-used features.

2. **ADR-010 Not Implemented (HIGH/UX):** The decision to feature-gate Memory, Insights, and Workspace behind a capability probe was made 2 days ago but never implemented. No `ServerCapabilities` model exists. Users see broken features (404 errors) instead of graceful "requires dashboard" notices.

Both are **cross-cutting**: every feature provider and the UI layer is affected.

---

## 2. Root Cause Analysis

### 2.1 Auth Key Bypass — How It Happened

After the EPIC Recovery (t_c7e1520f), the T13-R replacement tasks rebuilt the provider graph correctly for sessions, skills, workspace, memory, and insights — all consume `resolvedApiClientProvider`. But `chat_provider.dart` and `task_provider.dart` were written **before** the centralized provider existed and were **never updated** after it was introduced.

**Evidence:**

```
lib/features/chat/providers/chat_provider.dart:146
    final authManager = AuthManager(secureStorage: SecureStorage());
    ...
    apiClient: ApiClient(baseUrl: config.url, apiKey: apiKey)  // ← NO certificatePinner

lib/features/tasks/providers/task_provider.dart:115, 141, 570
    final authManager = AuthManager(secureStorage: SecureStorage());
    ...
    apiClient: ApiClient(baseUrl: activeServer.url, apiKey: apiKey)  // ← NO certificatePinner
```

**Compare with correct pattern:**

```
lib/core/providers/api_client_provider.dart:45-75
    final authManager = AuthManager(secureStorage: SecureStorage());
    final apiKey = await authManager.getApiKey();
    final pinner = await ref.watch(certificatePinnerProvider.future);  // ← AUD-001
    return ApiClient(
      baseUrl: activeServer.url,
      apiKey: apiKey,
      certificatePinner: pinner,  // ← TOFU protection PRESENT
    );
```

### 2.2 Security Impact — Certificate Pinning BYPASSED

This is **not just code duplication**. It is a security regression:

| Feature | Certificate Pinning (AUD-001) | VEC-002 MITM Protection |
|---------|-------------------------------|------------------------|
| Sessions | ✅ Active (via `resolvedApiClientProvider`) | ✅ Protected |
| Skills | ✅ Active (via `resolvedApiClientProvider`) | ✅ Protected |
| Workspace | ✅ Active (via `resolvedApiClientProvider`) | ✅ Protected |
| Memory | ✅ Active (via `resolvedApiClientProvider`) | ✅ Protected |
| **Chat** | ❌ **BYPASSED** | ❌ **Vulnerable** |
| **Tasks/Jobs** | ❌ **BYPASSED** | ❌ **Vulnerable** |

The bypass paths create `ApiClient` with `certificatePinner: null` — the constructor accepts it as optional. This was likely unintentional but has real security consequences: on compromised networks, chat and task API calls are susceptible to MITM attacks that would be caught by TOFU pinning.

### 2.3 Spec-Implementation Gap — ADR-010

ADR-010 was decided on 2026-07-08, specifying:

> "Feature-gate workspace, memory, and insights behind a capability probe. On connection, the client probes each endpoint; endpoints returning 404 are hidden with a 'requires Hermes Workspace dashboard' notice."

**Current state:** `grep -rn "ServerCapabilities" lib/` returns 0 results. Zero models, zero providers, zero probes. The features still render with 404 errors.

---

## 3. Proposed Target Architecture

### 3.1 Single Source of Truth for Auth

**New Provider Chain:**

```
SecureStorage (singleton)
    ↓
authManagerProvider ← Provider<AuthManager> (NEW — singleton)
    ↓
resolvedApiClientProvider ← FutureProvider<ApiClient?> (EXISTING — refactored)
    ↓
All feature providers (chat, tasks, sessions, skills, workspace, memory, insights)
```

**Changes:**

1. **Create `authManagerProvider`** — a singleton `Provider<AuthManager>` that creates exactly one `AuthManager(secureStorage: SecureStorage())` for the app lifetime.

2. **Refactor `resolvedApiClientProvider`** to read `authManagerProvider` instead of inline `AuthManager(secureStorage: SecureStorage())`. This eliminates the duplicate secure storage read and ensures a single source of truth.

3. **Refactor `chat_provider.dart`** — replace `AuthManager(secureStorage: SecureStorage())` + `ApiClient(...)` with `ref.watch(resolvedApiClientProvider).valueOrNull`.

4. **Refactor `task_provider.dart`** — same treatment for all 3 bypass locations.

5. **Remove dead `apiClientProvider`** (line 29) — it always returns `null` and has zero consumers.

**Files changed:**

| File | Change |
|------|--------|
| `lib/core/providers/api_client_provider.dart` | +`authManagerProvider`, refactor `resolvedApiClientProvider`, remove `apiClientProvider` |
| `lib/features/chat/providers/chat_provider.dart` | Replace bypass with `resolvedApiClientProvider` consumption |
| `lib/features/tasks/providers/task_provider.dart` | Replace 3 bypass locations |
| `lib/core/auth/auth_manager.dart` | No change (model is clean) |

### 3.2 Feature Gating via ServerCapabilities

**New Model:**

```dart
class ServerCapabilities {
  final bool memoryAvailable;
  final bool insightsAvailable;
  final bool workspaceAvailable;
  final bool skillsAvailable; // Always true on gateway
}
```

**Probe Strategy:**

Use `/v1/capabilities` endpoint if available (single round-trip). Fallback: per-endpoint HEAD requests with 2-second timeout. Probe runs during `ConnectionNotifier.connect()` health check, not blocking navigation (capabilities resolve asynchronously after the health check passes).

**Affected UI surfaces:**

| Surface | Before | After |
|---------|--------|-------|
| Bottom nav | 5 tabs (Chat, Sessions, Tasks, Workspace, Settings) | 4 or 5 tabs — Workspace hidden if unavailable |
| Settings → Agent Data | "Skills, Memory, Insights" — all shown | Only Skills shown; Memory/Insights show "Requires Hermes Workspace dashboard" |
| Router guard | No capability awareness | Routes for unavailable features redirect to /settings |
| Direct nav to /skills | Always accessible | Always accessible (gateway endpoint) |
| Direct nav to /memory | Always shows 404 error | Shows "This feature requires Hermes Workspace dashboard" |
| Direct nav to /insights | Always shows 404 error | Shows "This feature requires Hermes Workspace dashboard" |
| Direct nav to /workspace | Always shows 400 error | Hidden or shows dashboard notice |

---

## 4. Impact Analysis

### 4.1 Files Changed (auth fix)
- `lib/core/providers/api_client_provider.dart` — add `authManagerProvider`, remove dead `apiClientProvider`
- `lib/features/chat/providers/chat_provider.dart` — refactor `initialize()`
- `lib/features/tasks/providers/task_provider.dart` — refactor 3 locations

### 4.2 Files Changed (capability gating)
- `lib/models/server_capabilities.dart` — NEW: model
- `lib/core/providers/capabilities_provider.dart` — NEW: state provider
- `lib/core/router/app_router.dart` — read capabilities in redirect guard
- `lib/features/settings/presentation/settings_screen.dart` — conditionally show Agent Data entries
- `lib/core/router/app_router.dart` — `_ShellScaffold` conditionally show Workspace tab

### 4.3 Test Implications
- Existing tests for `chat_provider` and `task_provider` must pass after refactor (no API contract change)
- New tests for capability-gated UI states (available vs unavailable)
- One pre-existing test failure (`SettingsScreen Disconnect & Exit spinner`) — out of scope, flagged but not bundled

### 4.4 Regression Risk
- **LOW** — the refactored providers consume the same `ApiClient` interface; only the construction path changes
- **MEDIUM** — chat `initialize()` reads `getActiveServerConfig()` which may need to shift to `connectionProvider.activeServer`
- **NONE** — removing dead `apiClientProvider` has no consumers

---

## 5. Implementation Task Breakdown

### Wave 1: Foundation (parallel)
| Task | Title | Assignee |
|------|-------|----------|
| T1-auth | Create `authManagerProvider` + refactor `resolvedApiClientProvider` | flutter-state-engineer |
| T4-cleanup | Remove dead `apiClientProvider` | flutter-state-engineer |
| T6-model | Create `ServerCapabilities` model + tests | flutter-backend-db-architect |

### Wave 2: Migration (after T1-auth)
| Task | Title | Assignee |
|------|-------|----------|
| T2-chat | Refactor `chat_provider.dart` to consume `resolvedApiClientProvider` | flutter-state-engineer |
| T3-tasks | Refactor `task_provider.dart` to consume `resolvedApiClientProvider` | flutter-state-engineer |

### Wave 3: Feature Gating (after T6-model)
| Task | Title | Assignee |
|------|-------|----------|
| T7-probe | Implement endpoint probing during connection | flutter-state-engineer |
| T8-nav | Feature-gate Memory, Insights, Workspace in router + bottom nav | flutter-state-engineer |
| T9-settings | Feature-gate settings entries | flutter-state-engineer |

### Wave 4: Verification (after all code tasks)
| Task | Title | Assignee |
|------|-------|----------|
| T5-audit | Verify zero remaining `AuthManager` bypass instantiations | flutter-qa-tester |
| T10-cap-test | Add unit + widget tests for capability-gated states | flutter-qa-tester |
| T11-full-test | Full test suite verification | flutter-qa-tester |
| T12-docs | Update spec files (API contract, navigation, decisions) | flutter-documentation-steward |
| T13-device | Device verification & final gate | flutter-qa-tester |

---

## 6. Known Issues (Informational)

- **1 failing test:** `settings_screen_test.dart: SettingsScreen Disconnect & Exit button shows spinner when isBusy` — pre-existing, related to BUG-002-P1. Out of scope for this review.
- **Test count drift:** EPIC closure reported 403 tests; current state is 455 passed (+52 from 6-bug audit work). Baseline has shifted.
- **`getActiveServerConfig()` inconsistency:** `auth_manager.dart` line 60 is used by `chat_provider.dart` but no other provider; should standardize on `connectionProvider.activeServer` as the Riverpod source of truth.

---

## 7. Decision Summary

| Decision | Title | Status |
|----------|-------|--------|
| ADR-011 | Auth Manager Singleton via `authManagerProvider` | PENDING |
| ADR-012 | ServerCapabilities Implementation via Connection Probing | PENDING |
| ADR-013 | Remove dead `apiClientProvider` | PENDING |

All ADRs appended to `12_decision_log.md`.

---

## 8. Traceability

| LL Reference | Finding | Severity |
|-------------|---------|----------|
| LL-037 | Provider bypass anti-pattern — direct `ApiClient` construction bypasses cert pinning | HIGH |
| LL-038 | ADR without implementation — ADR-010 decided but never executed | HIGH |

Both appended to `00_lessons_learned.md`.

---

*End of Architecture Review — 2026-07-08*
*Task: t_62425b71 — Lead Architect Orchestrator*
*Triple Chinese MoA: deepseek-v4-pro + qwen3.7-max + glm-5.2*
