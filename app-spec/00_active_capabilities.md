# 00 — Active Capabilities

## Phase: MVP (2026-07-04)

| Feature | ID | Status |
|---------|-----|--------|
| Server Connection | F-001 | Gherkin validated — 14 scenarios: all 5 states covered |
| Chat (SSE) | F-002 | Gherkin validated — 13 scenarios: all 5 states covered |
| Sessions | F-003 | Gherkin validated — 14 scenarios: all 5 states covered |
| Tasks/Cron | F-004 | Gherkin validated — 14 scenarios: all 5 states covered |
| Skills Browser | F-005 | Gherkin validated — 9 scenarios: all 5 states covered |
| Workspace Browser | F-006 | Gherkin validated — 11 scenarios: all 5 states covered |
| Memory & Insights | F-007 | Gherkin validated — 7 scenarios: all 5 states covered |
| Settings | F-008 | Gherkin validated — 11 scenarios: Profile switching + all 5 states covered |

## Spec Gate Status (2026-07-05)

- **93 Gherkin scenarios** in `app-spec/09_testing_acceptance.md` — all 8 features covered
- **All scenarios** use Given/When/Then format with traceable AC-F{feature}-{num} IDs
- **All five screen states** (Loading, Empty, Error, Success, Offline) covered across all features per 03_user_flows_navigation.md §States
- **Profile switching** (F-008): Hermes Agent profile switching distinguished from server switching — AC-F008-08, AC-F008-09
- **All minor edge cases** addressed: URL normalization, large file rejection, double-send prevention, last-session delete, long-title truncation, already-running guard, pagination, license link
- **Gate status:** PASSED — ready for implementation

## Resolution History

| Issue | Resolution | Date |
|-------|-----------|------|
| Missing Offline states | Offline = server unreachable with cache fallback. 8 offline scenarios added. | 2026-07-05 |
| F-008 "Profile switching" ambiguity | Profile switching = Hermes Agent profiles (not server switching). AC-F008-08, AC-F008-09 added. | 2026-07-05 |
| Missing Loading states | Loading scenarios added for F-001, F-004, F-005, F-006. F-002 and F-007 already had loading states. | 2026-07-05 |
| Minor edge cases | All 6 edge cases from prior audit addressed with dedicated scenarios. | 2026-07-05 |

## Disabled (Future)
- Voice input, TTS, Widget, Notifications, Multi-account
