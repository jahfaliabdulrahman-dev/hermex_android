# Changelog

> All notable changes to Hermex Android are documented here.

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
