# Changelog

> All notable changes to Hermex Android are documented here.

## [0.1.0-rc4] — 2026-07-11

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
