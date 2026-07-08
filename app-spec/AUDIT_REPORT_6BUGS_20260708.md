# AUDIT REPORT — 6 Critical Bugs
# hermex_android | Date: 2026-07-08
# Auditor: flutter-lead-architect (Triple Chinese MoA + 10-profile swarm)

## Gateway Verification — ALL 10 PROFILES RUNNING ✅

```
flutter-lead-architect       triple-chinese         running
flutter-product-steward      deepseek-v4-pro        running
flutter-ui-ux-designer       deepseek-v4-pro        running
flutter-backend-db-architect deepseek-v4-pro        running
flutter-state-engineer       deepseek-v4-pro        running
flutter-qa-tester            deepseek-v4-pro        running
flutter-zero-trust-auditor   deepseek-v4-pro        running
flutter-devops-release-eng   deepseek-v4-pro        running
flutter-documentation-steward deepseek-v4-flash     running
flutter-curiosity-hunter     deepseek-v4-pro        running
```

## API Server Endpoint Verification (Hermes v0.18.0 on :8642)

| Endpoint | Status | Implication |
|----------|--------|-------------|
| GET /health | 200 ✅ | Gateway healthy |
| GET /v1/models | 200 ✅ | Models API exists |
| GET /v1/skills | 200 ✅ | Skills API exists |
| GET /api/sessions | 200 ✅ | Sessions API exists |
| GET /v1/chat/completions | 200 ✅ | Chat API exists |
| GET /v1/memory | **404 ❌** | **DOES NOT EXIST on this gateway** |
| GET /v1/insights | **404 ❌** | **DOES NOT EXIST on this gateway** |
| GET /v1/workspace | **404 ❌** | **DOES NOT EXIST on this gateway** |

---

## BUG 1: Chat Model Selector Broken 🔴 CRITICAL

### User Report (Arabic)
"حيث تحاول المراسلة وهنا يظهر خطأ بأنه علي ان احدد الموديل ولكن زر الموديل ما يفتح شيء و أصلا زر الموديل ما ادري ماهو الفايده منه"

### User Report (English)
"When trying to chat, error says 'must select model' but the model button doesn't open anything. I don't even know what the model button is for."

### Root Cause Analysis

**FILE: `lib/features/chat/presentation/chat_input.dart:218`**
```dart
onTap: models.isNotEmpty                    // ← DEAD CONDITION
    ? () => ModelSelector.show(...)
    : null,                                  // ← Button silently disabled
```

**FILE: `lib/features/chat/providers/chat_provider.dart:217-222`**
```dart
if (state.selectedModelId == null) {
  state = state.copyWith(
    errorMessage: 'No model selected. Please select a model.',  // ← User sees this
  );
  return false;
}
```

**TRACE: Full failure chain →**

1. `ChatNotifier.initialize()` (line 101) creates ChatRepository with API key from `AuthManager`
2. `initialize()` calls `loadModels()` (line 132)
3. `loadModels()` (line 147) calls `_repository!.getModels()` → `GET /v1/models`
4. **If this API call FAILS** (auth error, network error, timeout):
   - `catch` block (line 164-173): `errorMessage: 'Failed to load models. Using last known model.'`
   - `availableModels` stays `[]` (empty)
   - `selectedModelId` stays `null`
5. **`_ModelButton`** in chat_input.dart receives `models: []` → `onTap: null` → **BUTTON IS DEAD**
6. User types message and sends → `sendMessage()` (line 217) checks `selectedModelId == null` → **BLOCKS with error**

**PROBABLE UNDERLYING CAUSE (one of):**

| Cause | Probability | Evidence |
|-------|------------|----------|
| **A: Wrong API key saved in Flutter app** | 90% | `/v1/models` returns 200 with correct `API_SERVER_KEY` but 401 with config `HERMES_API_KEY`. If user connected with the wrong key, models API auth fails → empty list → button dead. |
| B: Connection screen stores model provider key, not API server key | 80% | The connection screen asks for "API Key" — ambiguous. User may have entered the model provider's key instead of `API_SERVER_KEY` from `.env` |
| C: AuthManager.getApiKey() returns null | 30% | If secure storage read fails silently |
| D: Server URL wrong | 10% | Would affect all endpoints uniformly |

**USER EXPERIENCE IMPACT:** "بلا أي قيمة" (literally worthless) — the CORE feature (chat) is broken. This makes the app useless.

### MOC / Fix Plan

```pseudocode
MOC-B1: Model Selector Recovery
├── Phase 1: Diagnostics (NON-BREAKING)
│   ├── Add auth_status check: test GET /v1/models with stored key
│   ├── If 401 → show "API key invalid. Please reconnect." with CTA
│   ├── If 200 but empty list → show "No models returned from server"
│   └── If network error → show retry button
│
├── Phase 2: Fallback UX
│   ├── If models load fails BUT chat still possible:
│   │   ├── Use last-known model from SharedPreferences (settings)
│   │   ├── Show manual model name input (text field) as fallback
│   │   └── Button ALWAYS tappable → shows diagnostic + manual input
│   │
│   └── Recovery: "Reconnect" button on model selector empty state
│
├── Phase 3: Connection Screen Clarity
│   ├── Add helper text: "Use API_SERVER_KEY from ~/.hermes/.env"
│   ├── Auto-detect which key was provided (model vs server)
│   └── Pre-fill from clipboard or suggest default
│
└── Acceptance Criteria:
    ├── Model button ALWAYS responds (never dead-tap)
    ├── Error messages are actionable (not just "no model selected")
    └── User can type model name manually as last resort
```

---

## BUG 2: Sessions Page Empty 🟠 HIGH

### User Report
"صفحة الجلسات تظهر فاضية"
"Sessions page shows empty"

### Root Cause Analysis

**FILE: `lib/features/sessions/providers/session_provider.dart:21-53`**
```dart
final sessionListProvider = FutureProvider<List<SessionSummary>>((ref) async {
  final repository = ref.watch(sessionRepositoryProvider);
  if (repository == null) {
    throw StateError('No active server — cannot fetch sessions.');  // ← ERROR state
  }
  try {
    return await repository.getSessions();  // → GET /api/sessions
  } catch (e) {
    final cached = await repository.getCachedSessions();
    if (cached.isNotEmpty) { return converted; }
    rethrow;  // ← Falls through to error
  }
});
```

**WHAT HAPPENS:**

1. `sessionRepositoryProvider` (line 10) depends on `resolvedApiClientProvider` — returns null if no API key
2. If API key is wrong/missing → repository is null → `StateError` thrown
3. If API key is correct but server unreachable → API call fails → try cache fallback
4. If cache is empty → error propagates to UI → **error state displayed with retry button**
5. If API key is correct AND server reachable → `/api/sessions` returns 200 ✅ → sessions shown

**VERIFIED:** `/api/sessions` returns 200 with `API_SERVER_KEY` on this gateway — endpoint WORKS.

**PROBABLE CAUSE:** Same as BUG 1 — wrong API key stored in Flutter app → all `/api/*` calls return 401.

**USER EXPERIENCE:** "تظهر فاضية" — user sees empty or error state, not knowing sessions exist on server.

### MOC / Fix Plan
```pseudocode
MOC-B2: Sessions Data Loading
├── Phase 1: Auth Dependency Resolution
│   ├── sessionRepositoryProvider must verify key validity BEFORE fetch
│   └── If 401 → prompt reconnect with correct key
│
├── Phase 2: UI State Clarity  
│   ├── Distinguish "empty (no sessions exist)" vs "can't reach server"
│   └── Show server status indicator on sessions page
│
└── Acceptance: Sessions visible when API key is correct
```

---

## BUG 3: Workspace Page Broken 🟠 HIGH

### User Report
"صفحة Workspace تظهر خطا في جلب البيانات وبرضه ما ادري ايش الفايده منها"
"Workspace page shows data fetch error. I don't even know what it's useful for."

### Root Cause Analysis — **TWO independent failures**

**FAILURE 1: API endpoint DOES NOT EXIST on this gateway**

**VERIFIED:** `curl GET /v1/workspace` → **HTTP 404** on Hermes v0.18.0

The `/v1/workspace` endpoint is a **dashboard/workspace API**, NOT a core Hermes gateway endpoint. It exists in `hermes-workspace` (the web UI dashboard on port 9119), not on the gateway (port 8642). The Flutter app tries to hit the gateway for this endpoint.

**FILE: `lib/features/workspace/data/workspace_repository.dart:31-32`**
```dart
final endpoint = cleanPath.isEmpty
    ? ApiEndpoints.workspace       // → /v1/workspace
    : ApiEndpoints.workspacePath(cleanPath);  // → /v1/workspace/{path}
```

**FAILURE 2: Purpose unclear to user**

The user explicitly states "ما ادري ايش الفايده منها" (I don't know what it's useful for). The workspace page has no explanatory text, no onboarding, no tooltip explaining what it does. It's a file browser for the server filesystem — but this is never communicated to the user.

**SPEC DRIFT:** `06_api_contract.md` documents `/v1/workspace` as a gateway endpoint (added per LL-010), but it was NEVER verified against the actual gateway. The spec was updated based on assumption, not evidence.

### MOC / Fix Plan
```pseudocode
MOC-B3: Workspace Recovery
├── Phase 1: API Discovery
│   ├── Option A: Query dashboard (port 9119) for workspace data
│   │   └── Requires dashboard running + session token
│   ├── Option B: Remove workspace feature (not supported by gateway)
│   │   └── Add user-facing note: "Workspace requires hermes-workspace dashboard"
│   └── Option C (RECOMMENDED): Feature-flag workspace
│       └── capabilities endpoint check → hide if unsupported
│
├── Phase 2: UX
│   ├── Add purpose description: "Browse your agent's filesystem"
│   └── Show connection requirement
│
└── Acceptance: Either works correctly OR clearly states it's unavailable
```

---

## BUG 4: Settings Shows Wrong Profile Name 🟡 MEDIUM

### User Report
"صفحة الاعدادات تظهر ان البروفايل هو flutter-state-engineer وهذا غريب هل هذا اسم ثابت والا السيرفر خاص به والا ايش بالضبط"
"Settings shows profile as 'flutter-state-engineer'. Is this a fixed name? Or does it belong to a specific server? What exactly is this?"

### Root Cause Analysis — **HARDCODED LITERAL**

**FILE: `lib/features/settings/presentation/settings_screen.dart:262`**
```dart
title: Text(
  'flutter-state-engineer',     // ← HARDCODED STRING. NEVER CHANGES.
  style: theme.textTheme.bodyLarge?.copyWith(
    color: HermesColors.textPrimary,
  ),
),
```

**THIS IS A FIXED STRING, NOT AN API CALL.** The profile name shown to the user has NOTHING to do with:
- The connected server
- The Hermes profile running the gateway
- The app's configured identity
- Any API response

It is literally the string `'flutter-state-engineer'` — the swarm profile name of the agent that built this widget. This was a **placeholder that was never replaced** with actual logic.

**WHY it shows 'flutter-state-engineer':** The State Engineer profile built the settings screen during implementation. They hardcoded their own profile name as a placeholder, intending to replace it with dynamic logic later. The task was marked "done" before the dynamic logic was implemented. This is a **router wiring gap** (see LL-017, LL-020) — feature was "done" on paper but had placeholder values in production code.

### MOC / Fix Plan
```pseudocode
MOC-B4: Dynamic Profile Name
├── Option A: Read from connected server
│   └── GET /v1/capabilities → extract profile info (if available)
│
├── Option B: Read from app-level config
│   └── Store profile name during connection flow
│   └── AuthManager.getActiveServerConfig() → extract label/name
│
├── Option C (RECOMMENDED): Use server label
│   └── The server has a user-given label → show that
│   └── Fallback: server URL hostname
│
└── Acceptance: Shows actual connected server's identifier
```

---

## BUG 5: Agent Data — All 3 Broken 🔴 CRITICAL

### User Report
"مربع Agent Data فيه ثلاث عناصر كلها لا تعمل (Skills, Memory, Insights)"
"Agent Data box has 3 items, all not working: Skills, Memory, Insights"

### Root Cause Analysis — **TWO categories of failure**

**Skills → `/v1/skills`**

✅ ENDPOINT EXISTS on gateway (HTTP 200 with correct auth)
❌ Broken: Same auth issue as BUG 1/2 — wrong API key → 401 → empty list

**FILE: `lib/features/skills/data/skills_repository.dart:20-36`**
- Returns `[]` if `_apiClient` is null (graceful degradation per LL-006)
- BUT if apiClient exists but auth fails → exception → error screen shown

**Memory → `/v1/memory`**

❌ ENDPOINT DOES NOT EXIST on Hermes v0.18.0 gateway → **HTTP 404**

**FILE: `lib/features/memory/providers/memory_provider.dart:31`**
```dart
final response = await apiClient.get(ApiEndpoints.memory);  // → GET /v1/memory → 404
```
- `ApiClient.get()` throws `ClientException` on 404
- Provider throws `Exception('Failed to load memory entries: $e')`
- Screen shows error state

**Insights → `/v1/insights`**

❌ ENDPOINT DOES NOT EXIST on Hermes v0.18.0 gateway → **HTTP 404**

**FILE: `lib/features/insights/providers/insights_provider.dart:30`**
```dart
final response = await apiClient.get(ApiEndpoints.insights);  // → GET /v1/insights → 404
```
- Same failure pattern as memory

### Root Cause Summary

| Item | Endpoint | Gateway Status | Why Broken |
|------|----------|---------------|------------|
| Skills | `/v1/skills` | EXISTS (200) | Auth key likely wrong in app |
| Memory | `/v1/memory` | **DOES NOT EXIST (404)** | Gateway doesn't serve this endpoint |
| Insights | `/v1/insights` | **DOES NOT EXIST (404)** | Gateway doesn't serve this endpoint |

**SPEC DRIFT:** `06_api_contract.md` documents `/v1/memory` and `/v1/insights` as gateway endpoints, but these were NEVER verified. They're dashboard-level APIs (port 9119), not gateway APIs (port 8642). This is the SAME bug class as BUG 3 (workspace).

### MOC / Fix Plan
```pseudocode
MOC-B5: Agent Data Recovery
├── Skills:
│   ├── Fix auth key → should work immediately
│   └── Add auth error → reconnect prompt
│
├── Memory + Insights:
│   ├── OPTION A: Redirect to dashboard (port 9119) for these features
│   │   └── Needs dashboard running + session token
│   ├── OPTION B: Hide features that don't exist on gateway
│   │   └── Use /v1/capabilities to feature-gate
│   ├── OPTION C (RECOMMENDED): Feature-flag + graceful degradation
│   │   ├── On app start: probe /v1/capabilities or /v1/memory
│   │   ├── If 404: hide "Memory" and "Insights" from Agent Data
│   │   └── Show: "Memory & Insights require Hermes Workspace dashboard"
│   │
│   └── OPTION D: Implement via dashboard API proxy
│       └── Route /v1/memory → http://server:9119/api/memory
│
└── Acceptance:
    ├── Skills: works with correct auth
    ├── Memory: either works OR clearly states "needs dashboard"
    └── Insights: either works OR clearly states "needs dashboard"
```

---

## BUG 6: Danger Zone Dialogs — Invisible Text 🟡 MEDIUM

### User Report
"مربع Danger Zone كل عناصره الثلاث تعمل ولكن لما تضغط على احدهم يظهر مربع فاضي مع زرين بألوان ما اقدر اشوف ايش اللي مكتوب"
"Danger Zone — all 3 items work, but clicking shows empty dialog with 2 colored buttons where I can't see what's written"

### Root Cause Analysis — **THEME TEXT COLOR CONTRAST**

**FILE: `lib/features/settings/presentation/settings_screen.dart:426-534`**
**Three dialogs affected:**
1. `_showDeleteConfirmation` (line 426)
2. `_showResetConfirmation` (line 456)  
3. `_showDisconnectConfirmation` (line 489)

All three use:
```dart
AlertDialog(
  backgroundColor: HermesColors.surface,  // #161B22 (dark)
  title: const Text('Delete All Data?'),  // NO explicit text color
  content: const Text('...'),             // NO explicit text color
  actions: [...]
)
```

**FILE: `lib/core/theme/app_theme.dart:144-149`**
```dart
dialogTheme: DialogThemeData(
  backgroundColor: HermesColors.surface,  // ← ONLY bg + shape set
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(28),
  ),
),
```

**THE PROBLEM:**

The `DialogThemeData` does NOT specify `titleTextStyle` or `contentTextStyle`. In Material 3, `AlertDialog` uses:
- Title: `dialogTheme.titleTextStyle` → falls back to `textTheme.headlineSmall`
- Content: `dialogTheme.contentTextStyle` → falls back to `textTheme.bodyMedium`

These text styles ARE defined with explicit `HermesColors.textPrimary` color in `HermesTextTheme.buildTextTheme()`. So text SHOULD be visible (#E6EDF3 on #161B22).

**HOWEVER:** The `const Text(...)` widgets in the dialog might not properly inherit the theme's text styles due to how Flutter resolves `DefaultTextStyle` inside `AlertDialog`. In some Material 3 configurations, `AlertDialog` creates its own `DefaultTextStyle` with `colorScheme.onSurface` which may not match.

**MOST LIKELY SCENARIO:** The `AlertDialog` uses `ColorScheme.fromSeed()` which computes `onSurface` from the seed color. With seed `HermesColors.navy` (#001F5E) and brightness `dark`, `onSurface` SHOULD be light — but the computed color may be wrong or the `AlertDialog`'s internal `DefaultTextStyle` may override with a color that blends into `HermesColors.surface` (#161B22).

**SECONDARY ISSUE:** The dialog uses `const Text(...)` — compile-time constants. These don't respond to theme changes at runtime and may use default Material text color which in dark mode could be light gray on light gray.

**VERIFICATION NEEDED:** Run the app on device → tap Danger Zone button → visually confirm text visibility.

### MOC / Fix Plan
```pseudocode
MOC-B6: Dialog Text Visibility
├── Phase 1: Explicit Text Colors
│   ├── ALL dialog content MUST have explicit TextStyle with color
│   ├── title: TextStyle(color: HermesColors.textPrimary)
│   ├── content: TextStyle(color: HermesColors.textSecondary)  
│   └── Remove 'const' from Text widgets in dialogs
│
├── Phase 2: Dialog Theme Fix
│   ├── Add titleTextStyle and contentTextStyle to DialogThemeData
│   └── Verify contrast ratio > 4.5:1 on surface background
│
├── Phase 3: Button Color Contrast
│   ├── FilledButton on error bg: ensure white foreground
│   └── TextButton: ensure cyan foreground is visible
│
└── Acceptance: All dialog text readable on device
```

---

## Cross-Cutting Issues

### X1: API Key Ambiguity 🔴
The Flutter app has NO indication of which API key to use. The connection screen says "API Key" — but the Hermes gateway has MULTIPLE keys:
- `HERMES_API_KEY` (model provider key — for LLM calls)
- `API_SERVER_KEY` (gateway API server key — for `/v1/*` and `/api/*` endpoints)

The app needs `API_SERVER_KEY`. Users likely enter the model provider key, causing 401 on all endpoints.

**AFFECTS:** Bugs 1, 2, 5-Skills

### X2: Spec-Implementation Gap — 3 endpoints assumed, 0 verified 🔴
`/v1/memory`, `/v1/insights`, `/v1/workspace` were added to `06_api_contract.md` and `lib/core/api/endpoints.dart` during implementation but **never verified against the actual gateway**. All three return 404.

This is the same class of bug as LL-010 (spec drift) — features were built assuming dashboard APIs are gateway APIs.

**AFFECTS:** Bugs 3, 5-Memory, 5-Insights

### X3: Silent Failure Chains 🔴
When the API key is wrong:
- Models fail to load → model button silently disabled (no error shown)
- Sessions fail → error state shown (but error message is technical)
- Skills fail → error state shown

None of these surface the actual problem: "Your API key is wrong." Each feature fails independently with different error messages.

### X4: Hardcoded Placeholders in Production 🟡
`flutter-state-engineer` on settings_screen.dart:262 is a development placeholder that reached production. This is a **router wiring gap** class of bug (LL-017, LL-020) — the implementation task was marked "done" with placeholder values still in code.

---

## Summary: Priority Matrix

| Bug | Severity | Root Cause Class | Affects |
|-----|----------|-----------------|---------|
| BUG 1: Model Selector | 🔴 CRITICAL | Auth key + silent failure chain | Core chat feature |
| BUG 5: Agent Data | 🔴 CRITICAL | Auth key (Skills) + missing endpoints (Memory, Insights) | 3 features |
| BUG 2: Sessions Empty | 🟠 HIGH | Auth key dependency | Session management |
| BUG 3: Workspace Broken | 🟠 HIGH | Missing endpoint (404) | Workspace feature |
| BUG 4: Wrong Profile Name | 🟡 MEDIUM | Hardcoded placeholder | Settings UX |
| BUG 6: Invisible Dialog Text | 🟡 MEDIUM | Theme contrast | Danger Zone UX |

**FIX ORDER:** BUG 1 + BUG 5-Skills first (fix auth key → unblocks multiple features), then BUG 2 (same fix), then endpoint issues (BUG 3 + BUG 5-Memory/Insights), then UX (BUG 4, BUG 6).
