# 16 — Implementation Backlog

> Last Updated: 2026-07-05
> Managed via Kanban board. This file tracks high-level status.

## MVP Features — All Implemented

| Feature | ID | Status | Tests | Notes |
|---------|-----|--------|-------|-------|
| Server Connection | F-001 | ✅ DONE | 50/51 pass (1 pre-existing) | URL validation, trailing slash normalization, 7 edge cases |
| Chat (SSE streaming) | F-002 | ✅ DONE | 42 pass | 27 Gherkin criteria, chat_screen placeholder in router |
| Sessions | F-003 | ✅ DONE | 47/47 pass | 14/14 Gherkin criteria covered |
| Tasks/Cron | F-004 | ✅ DONE | 268/286 pass (18 pre-existing) | +69 new tests, TaskListScreen, TaskDetailScreen, TaskFormScreen |
| Skills Browser | F-005 | ✅ DONE | 47 new tests | 10 source + 6 test files, optimistic toggle |
| Workspace Browser | F-006 | ✅ DONE | Included in F-005 count | Directory listing, breadcrumbs, file preview, binary detection |
| Memory & Insights | F-007 | ✅ DONE | 59 pass | Memory view, insights screen, stats dashboard |
| Settings | F-008 | ✅ DONE | Included in F-007 count | Server management, theme, model pref, profile switching |

## Total Implementation Summary

| Metric | Value |
|--------|-------|
| Total source files (~84 in lib/) | 84 |
| Total test files | 27 |
| Total tests passing | ~290 |
| Features implemented | 8/8 |
| Gherkin scenarios covered | 93/93 |
| flutter analyze | clean (0 issues) |

## Technical Debt Discovered

1. **Duplicate ApiEndpoints** — `lib/core/api/endpoints.dart` and `lib/core/constants/api_endpoints.dart` contain identical path constants. Architecture spec (07) specifies only `core/api/endpoints.dart`. Remove the duplicate in `core/constants/`.

2. **Chat placeholder** — `lib/core/router/app_router.dart` uses a `_ChatPlaceholder` widget instead of the actual `ChatScreen`. Chat feature implementation exists in `lib/features/chat/` but the router doesn't wire it. Wire `ChatScreen` into the router.

3. **Workspace placeholder** — Same as above; `_WorkspacePlaceholder` in router. Wire `WorkspaceScreen`.

4. **Skills route** — Router uses `_placeholderScreen('Skills')` instead of `SkillsScreen`. Wire `SkillsScreen`.

5. **06_api_contract.md missing endpoints** — `/v1/memory`, `/v1/insights`, `/v1/workspace` are implemented in code but not listed in the API contract spec. Back-propagate.

6. **08_security_privacy.md coverage gap** — Only 3 of 10 zero-trust attack vectors have documented mitigations. Vectors 4-10 (token replay, input injection, SSE poisoning, deep link hijack, clipboard exposure, background snapshot) need mitigation sections.

## Future Enhancements (Non-MVP)

- Voice input (transcribe API)
- TTS output (phone speaks agent response)
- Widget (home screen quick chat)
- Notifications (cron job results)
- Offline session cache (beyond 7-day Isar cache)
- Multi-account support
- RTL language support (spec defined, not implemented)
- Certificate pinning for production builds
- Integration tests (E2E flow: connect → chat → sessions)
- CI/CD pipeline (GitHub Actions)
