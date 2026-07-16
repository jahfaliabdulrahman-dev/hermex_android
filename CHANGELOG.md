# Changelog

> All notable changes to Hermex Android are documented here.

## [0.2.0-rc6] — 2026-07-16

### Added

- **Hermes Profile as First-Class Entity** — Introduced `HermesProfile` as a first-class Isar entity carrying per-profile `defaultModelId` and `reasoningEffort` fields, replacing the flat `ServerConfig` model. Owner-approved as the canonical unit of server identity. (ADR-010, C.11)
- **Model Selector Wired End-to-End** — Model selection UI (`model_selector.dart`) is now fully wired: selected model is propagated to the chat API request and persisted per-profile. Previously dead code. (D.14–D.18)
- **Reasoning-Effort Control** — Per-profile reasoning-effort/thinking control plumbed end-to-end. `reasoningEffort` field travels with the profile and is sent in chat API requests. (E.19–E.20)
- **Session Search with Server-Side Pagination** — Session search upgraded from client-side filtering of the full list to server-side query with pagination/cursor support. (G.24)

### Fixed

- **Chat Screen Stale Session Bug** — Switching between sessions in the bottom-nav ShellRoute showed stale data from the first session. Root cause: `const NoTransitionPage` returned the same Page object regardless of URL params, so Flutter never detected the route change and `didChangeDependencies()` never fired. Fixed by adding `ValueKey(state.uri.toString())` to force widget rebuild on session switch. (hotfix 2026-07-16)
- **Stale AppBar Title on Untitled Sessions** — Opening an untitled session kept the previous session's title/model-name in the AppBar. Root cause: `ChatState.copyWith()` falls back to `this.sessionTitle` when `clearSessionTitle` is false and `sessionTitle` is null — untitled sessions pass `null` title from the API. Fixed by setting `clearSessionTitle: true` and `clearSessionModelName: true` when values are null/empty. (hotfix 2026-07-16)
- **ChatMessage JSON Parsing** — `ChatMessage.fromJson()` hardened to accept null/invalid message content fields without crashing. (hotfix 2026-07-16)
- **Error-Handling Architecture Rebuilt** — Fixed Dio interceptor chain: tight `validateStatus` (correctly throws on 4xx), `onError` interceptor now calls `handler.reject()` with the classified exception (not the original DioException), and `_sanitizeError()` applied uniformly across all 8+ error sites (sessions, chat, stream, tasks). Previously `AuthException`/`ClientException` were defined but dead code. (A.1–A.5)
- **Certificate Pinning Uniform** — All `ApiClient` instances now go through `resolvedApiClientProvider` which wires `certificatePinner`. Chat and Tasks providers previously bypassed pinning entirely. (B.7–B.10)
- **Profile Switching Reactively Resets Chat State** — `ChatNotifier` now reactively watches `connectionProvider`; switching profiles mid-chat-session resets chat state to the new server/ApiClient. Previously chat silently talked to the old server until manual "New Chat." (C.12)
- **Server Config Foreign Key Fixed** — `CachedSession.serverId` now uses actual `ServerConfig.id` instead of fragile `baseUrl`. (C.13)
- **_SizeLimitInterceptor Covers Map Responses** — OOM-protection guard now checks `data is Map` (the dominant API response shape) in addition to `String` and `List`. (A.6)
- **Orphaned "Default Model" Setting Wired** — Settings screen's free-text "Default Model" field is now read by `chat_provider.dart` and bound to the active profile. (D.17)
- **Task Model Field Bound to Server Model List** — Task form's model field is now a dropdown selector against the live `/v1/models` list, not free-text. (D.18)

### Changed

- **Light Theme Complete Pass** — Agent bubble background adapts to theme brightness (no longer hardcoded `#161B22`). All `textDisabled` instances converted to theme-adaptive tokens. Visual consistency audit completed across all screens (settings, insights, sessions, chat). (F.21–F.23)
- **ModelInfo Extended** — `ModelInfo` now carries capability and reasoning-effort metadata fields. (D.16)

### Removed

- **FLAG_SECURE Permanent Removal** — All three locations in `MainActivity.kt` (`onCreate`, `onResume`, `onWindowFocusChanged`) removed. Owner-confirmed as permanent — do not re-add. Verified via `grep -rn "FLAG_SECURE" android/` → 0 matches. (G.25, ADR-011)
- **Duplicate `_classifyError` Removed** — Error classification logic consolidated into the single shared `api_client.dart` utility; divergent copy in `task_repository.dart` removed. (A.5)
- **Dead Certificate Pinner Stub Removed** — `apiClientProvider` always-returning-null stub removed. (B.10)

### Process Integrity

- **Gate4 Rescan Incident (H.26)** — RC5 Gate2 REJECTED over AUD-RC5-001/002. A same-day "Gate4 rescan" declared PASS without retesting the specific rejected findings. RC6 proved AUD-RC5-001 still live. New rule codified in ADR-012: any PASS after REJECT must re-test the SPECIFIC findings with evidence attached. Gate tasks must include a "Results / Evidence" field.

### Technical

- `flutter analyze` — 0 errors
- `flutter test` — 529/529 passing
- RC6 defects: 26 fixed across categories A–H + NB-1/NB-2 + 3 hotfixes
- Files changed: 21
- Baseline commit: `0a2532c`
- Release APK: 65.8MB signed; Debug APK: 178MB; smoke-tested on TECNO LJ7

## [0.1.0-rc5] — 2026-07-11

### Fixed

- **REG-1: Chat duplicate message on non-session history** — Fixed bug where sending a message without an active session created a duplicate user message in the API request body, causing Hermes API to reject with "Invalid argument: Contains invalid characters." The state mutation order was corrected: `_buildHistory()` now runs BEFORE `state.copyWith()` adds the new message. (LL-029 rule codified via LL-038)
- **REG-2: Light theme tokens not wired** — `AppTheme.buildLight()` was defined with full color tokens but never connected to the widget tree via `MaterialApp.themeMode`. Light mode now renders correct colors (cyanAdapted `#0077A3`, light surface, text, and outline tokens). Added `onSurfaceVariant` token to both dark and light color schemes. (hotfix b6445df, feat 4998d31)
- **REG-3: ApiException.toString() server body leak** — `ApiException.toString()` exposed raw server response body in debug logs and error messages, risking internal server data leak to UI. Fixed by implementing safe string representation. (fd608c9, 5ae2e66)
- **REG-4: _sanitizeError() removed causing server body leak** — The `_sanitizeError()` method was inadvertently removed during a refactor, causing raw server error body to be displayed in UI error toasts. Restored with test coverage. (d255d74)

### Removed

- **RC4 takedown** — RC4 release was pulled due to REG-2 (light theme unreachable), REG-3 (API leak), and REG-4 (server body leak). Users are advised to update to RC5.

### Technical

- `flutter analyze` — 0 errors (3 issues: 1 const-eval in chat_input.dart, 1 unused param in test, 1 const constructor lint — non-blocking)
- `flutter test` — 484/484 passing
- Baseline commit: `4998d31`

## [0.1.0-rc4]

### Added

- **Light Theme** — Full Material 3 light mode with WCAG AA 4.5:1 minimum contrast ratio. Theme toggle in Settings (Dark / Light / System). Light mode adapts cyan accent from `#32C2FF` to `#0077A3` for sufficient contrast on light backgrounds. Dark remains default. (DEC-EPIC001-THEME)
- **Chat History Loading** — Sessions now load their chat history on screen mount. Chat provider fetches and displays previous messages from the active session. AppBar shows current session context (title/ID).
- **Chat Session Context** — New `chatWithSession` route helper provides navigation to the chat screen with pre-loaded session context, enabling deep linking from Sessions list.
- **Tasks: All Jobs Visible** — Tasks page now displays all 5 job types (chat, cron, memory, skills, workspace). Previous version only showed a subset.

### Fixed

- **Tasks: Pause Button** — Pause/Resume toggle on each job now correctly sends the pause API request and updates UI state. Previously the button was non-functional.
- **Dead Attachment Icon Removed** — Removed the non-functional attachment icon from the chat input field. Attachment feature was stubbed but never wired; the icon showed a no-op button.

### Changed

- **Theme Architecture** — `AppTheme` split into `buildDark()` / `buildLight()` so `ThemeMode` can swap. Colors centralized in `HermesColors` constants. (DEC-EPIC001-THEME)
- **Cyan Adaption Rule** — Light mode uses `#0077A3` instead of `#32C2FF` for accent elements (buttons, FAB, links) to maintain WCAG AA 4.5:1 contrast on white/light backgrounds.

### Technical

- `flutter analyze` — 0 errors
- `flutter test` — 484/484 passing
- Baseline commit: `8aec1db`
