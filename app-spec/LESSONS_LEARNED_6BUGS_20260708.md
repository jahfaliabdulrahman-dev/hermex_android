# Lessons Learned — 6 Critical Bugs Audit
# hermex_android | 2026-07-08

## New Lessons (LL-031 through LL-036)

---

### LL-031: Gateway Endpoint Assumption — Features built on non-existent APIs

- **Date:** 2026-07-08
- **Stage:** Post-Implementation Audit (6-bug investigation)
- **Source:** Abdulrahman's 6-bug report
- **Issue:** `/v1/memory`, `/v1/insights`, and `/v1/workspace` were implemented in the Flutter app and documented in `06_api_contract.md` as gateway endpoints — but ALL THREE return **HTTP 404** on the actual Hermes gateway (v0.18.0 on port 8642). These are **dashboard-level APIs** (hermes-workspace port 9119), NOT core gateway APIs.
- **Root Cause:** Implementers assumed that endpoints documented in the online Hermes Agent docs existed on the gateway. No one verified by actually hitting the endpoint with `curl`. The spec was updated based on documentation, not empirical evidence.
- **Impact:** 3 of 8 features (37.5%) were built on non-existent APIs. Memory, Insights, and Workspace — all return 404. The Flutter app code is correct but targeting the wrong server component.
- **Prevention Rule (PERMANENT):** Every API endpoint added during implementation MUST be verified with `curl` against the ACTUAL running gateway BEFORE code is written. Add an "Endpoint Verified" column to the Traceability Matrix. No feature may start implementation until its API endpoint returns 200 from the target server.
- **Linked Decision ID:** N/A (verification gap)
- **Severity:** 🔴 CRITICAL

### LL-032: Hardcoded Placeholder Values in Production — 'flutter-state-engineer' profile name

- **Date:** 2026-07-08
- **Stage:** Post-Implementation Audit
- **Source:** Abdulrahman — "هل هذا اسم ثابت" (Is this a fixed name?)
- **Issue:** `settings_screen.dart:262` hardcodes `'flutter-state-engineer'` as the profile name — a development placeholder that the State Engineer left in code during implementation. This is the swarm profile name of the agent that built the widget, NOT the user's server identity.
- **Root Cause:** The implementation task (F-007+F-008, t_1124d1c9) was marked "done" with placeholder values still in production code. No code review gate detected that a hardcoded string replaced what should have been dynamic logic. This is the SAME class of bug as LL-017 (Router Wiring Gap) — features marked complete with placeholders.
- **Impact:** User sees a meaningless swarm-internal profile name. Questions the app's reliability. The same `flutter-state-engineer` name shows for ALL users regardless of their server.
- **Prevention Rule:** Code review gate MUST flag any string literal that impersonates a user-facing identity (names, URLs, IDs). Add to QA checklist: "Are all user-facing names dynamic (from config/API) or clearly labeled as defaults?"
- **Linked Decision ID:** N/A (code review gap)
- **Severity:** 🟡 MEDIUM

### LL-033: Silent Failure Chains — Multiple features fail independently from single auth issue

- **Date:** 2026-07-08
- **Stage:** Post-Implementation Audit
- **Source:** Root cause tracing across 6 bugs
- **Issue:** A single wrong API key causes a cascading but SILENT failure across 5 features. Each feature fails independently with different error messages, none of which point to the actual problem ("wrong API key"):
  - Chat: "No model selected. Please select a model." (button is dead, user confused)
  - Sessions: Error state with "Failed to load sessions"  
  - Skills: Error state with "Failed to load skills"
  - Models don't load → model button silently disabled (no error at all)
- **Root Cause:** Each feature handles 401 independently with its own catch block and its own error message. No centralized auth error surfaced. The `ApiClient` classifies 401 as `AuthException` but no provider links auth failures to user-facing guidance.
- **Impact:** User reports 6 bugs when the root cause is 1 (wrong key) + 3 (missing endpoints). Debugging complexity is 6x the actual problem. User frustration is amplified by inconsistent error messages.
- **Prevention Rule:** Add a centralized `AuthErrorBanner` widget that listens for 401 responses from ANY API call and shows: "Authentication failed. Your API key may be incorrect. [Reconnect]" — with a single CTA. All features share this banner instead of independent error handling.
- **Linked Decision ID:** N/A (UX architecture gap)
- **Severity:** 🔴 CRITICAL

### LL-034: Capability Discovery Missing — No endpoint existence check before feature routing

- **Date:** 2026-07-08
- **Stage:** Post-Implementation Audit
- **Source:** Gateway endpoint verification (curl tests)
- **Issue:** The Flutter app has NO mechanism to discover which endpoints the connected server actually supports. Features are routed unconditionally — if Memory is in the menu, it navigates to MemoryScreen which calls `/v1/memory` regardless of whether the endpoint exists.
- **Root Cause:** The architecture assumed the Hermes gateway exposes ALL documented endpoints. No `capabilities` probe was designed. The `ApiEndpoints` class is a static list — no discovery, no negotiation, no graceful degradation.
- **Impact:** Users navigate to features that can never work. The app appears broken (loading spinner → error) instead of gracefully explaining the limitation.
- **Prevention Rule:** Implement a `capabilitiesProvider` (FutureProvider) that probes key endpoints on connection and exposes `ServerCapabilities` to the widget tree. Feature-gate all navigation based on capabilities. Unavailable features should show "requires dashboard" notices, not errors.
- **Linked Decision ID:** N/A (architecture gap)
- **Severity:** 🔴 CRITICAL

### LL-035: Dialog Text Invisibility — Dark theme dialog text contrast

- **Date:** 2026-07-08
- **Stage:** Post-Implementation Audit
- **Source:** Abdulrahman — "يظهر مربع فاضي مع زرين بألوان ما اقدر اشوف ايش اللي مكتوب"
- **Issue:** Danger Zone confirmation dialogs (`AlertDialog`) text is invisible or nearly invisible on the dark `HermesColors.surface` (#161B22) background. The `DialogThemeData` in `app_theme.dart` only specifies `backgroundColor` and `shape` — no `titleTextStyle` or `contentTextStyle`. The `const Text(...)` widgets in dialogs may not properly inherit text colors.
- **Root Cause:** Three compounding issues:
  1. `DialogThemeData` missing text style definitions
  2. `const Text(...)` widgets in dialogs (compile-time constants that don't respond to theme)
  3. Potential `DefaultTextStyle` override in `AlertDialog`'s internal widget tree
- **Impact:** User cannot read critical confirmation dialogs ("Delete All Data?", "Reset Preferences?") before taking destructive actions. This is a SAFETY issue — the user might confirm deletion without understanding consequences.
- **Prevention Rule:** All dialogs MUST have explicit `TextStyle` with explicit `color` for title and content. Remove `const` from dialog Text widgets. Add `titleTextStyle` and `contentTextStyle` to `DialogThemeData`. Add to QA device checklist: "Read every dialog text on physical device."
- **Linked Decision ID:** N/A (theme gap)
- **Severity:** 🟡 MEDIUM (🟠 elevated due to safety implications)

### LL-036: API Key Type Ambiguity — Model key vs API Server key

- **Date:** 2026-07-08
- **Stage:** Post-Implementation Audit
- **Source:** Gateway endpoint verification — `/v1/models` returns 401 with model key, 200 with API_SERVER_KEY
- **Issue:** The Hermes gateway accepts TWO different API keys for different purposes:
  - `HERMES_API_KEY` (model provider key from `config.yaml`) — used for LLM API calls to external providers
  - `API_SERVER_KEY` (from `.env`) — used for the gateway's own `/v1/*` and `/api/*` REST endpoints
  The Flutter app's connection screen asks for "API Key" without distinguishing which one. Users likely enter their model provider key → all API calls return 401 → 5 features appear broken.
- **Root Cause:** The connection screen was designed before the two-key architecture was understood. The `AuthManager` and `resolvedApiClientProvider` use whatever key was saved — with no validation that it's the correct TYPE of key.
- **Impact:** For the user, the distinction between `HERMES_API_KEY` and `API_SERVER_KEY` is invisible. The app appears "broken" for all features when the wrong key type is used.
- **Prevention Rule:** 
  1. Connection screen MUST include helper text: "Use the API_SERVER_KEY from your Hermes server (.env file)"
  2. `healthCheck()` in `ApiClient` should distinguish 401 from connection errors
  3. After connection, probe `/v1/models` — if 200, key is correct. If 401 with a different response shape, show: "This appears to be a model provider key, not an API server key. Please check your .env file."
  4. Document this distinction prominently in README and onboarding
- **Linked Decision ID:** N/A (UX + documentation gap)
- **Severity:** 🔴 CRITICAL

---

## Cross-Reference: Existing Lessons Relevant to These Bugs

| LL # | Lesson | Relevance to 6 Bugs |
|------|--------|---------------------|
| LL-010 | Spec-Implementation Gap — API contract missing endpoints | BUG 3,5: Endpoints documented but non-existent |
| LL-017 | Router Wiring Gap — code exists but not wired | BUG 4: Profile name was placeholder, never wired |
| LL-019 | Empty Catch Blocks in Auth Path | BUG 1,2,5: Silent auth failures |
| LL-022 | Silent API Key Redaction (`***` literal) | BUG 1,2,5: Previous key issue — now fixed but similar class |
| LL-023 | Fake Connection State — selectServer no health check | BUG 1,2,5: Connection succeeds but API calls fail silently |
| LL-029 | Duplicate Messages — state mutation before snapshot | BUG 1: Model selector state updated before validation |

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| New lessons | 6 (LL-031 through LL-036) |
| Endpoints verified | 8 (3 missing, 5 present) |
| Existing LL cross-references | 6 |
| Spec drift instances found | 3 |
| Placeholder values in production | 1 |
| Safety issues (dialog text) | 1 |
