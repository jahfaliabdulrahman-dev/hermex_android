# HUNT REPORT — SCSI L1 Full Scan
# hermex_android codebase
# Scan date: 2026-07-07T23:20:00Z (Cycle #4)

====================================================================
SCSI HUNT #4 | files scanned: 115+ | patterns matched: 10/17 | bugs found: 5 (3 resolved, 2 open)
====================================================================

## BUILD GATES

[PASS] flutter analyze — 0 issues (CLEAN)
[PASS] flutter test — 437/437 PASSED (+4 from Cycle #3)
[INFO] No new commits since Cycle #3. 9 uncommitted files with significant improvements.

====================================================================

## RESOLVED THIS CYCLE (verified in uncommitted diffs)

### R1: Duplicate _validateUrl — Single Source of Truth (LL-AUTO-20260707-duplicate_validateurl)
STATUS: RESOLVED | SEVERITY: MEDIUM → CLOSED

Evidence:
- `server_repository.dart:255`: `_validateUrl` → `static String? validateUrl(String url)` — public, static, testable
- `connection_screen.dart:60-67`: private `_validateUrl` now delegates to `ServerRepository.validateUrl()` after null/empty check
- `grep -rn '_validateUrl' lib/` returns ONLY `connection_screen.dart` — the one remaining private method is a thin delegation wrapper
- No semantic changes to validation logic — same 5 security rules enforced
- Pattern #16 in patterns.db can be marked inactive

### R2: BUG-002-P3 — ConnectionScreen AppBar Back Button
STATUS: RESOLVED | SEVERITY: LOW → CLOSED

Evidence:
- `connection_screen.dart:232-235`: `leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop())`
- User can now navigate back from ConnectionScreen without hardware back button

### R3: BUG-002-P2 — SkillsScreen AppBar Back Button
STATUS: RESOLVED | SEVERITY: MEDIUM → CLOSED

Evidence:
- `skills_screen.dart:56-59`: `leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop())`
- User can now navigate back from SkillsScreen without hardware back button
- Both dead-end screens (P2, P3) from BUG-002 now have navigation affordances

====================================================================

## NEW CODE — VERIFICATION PASSED

### Router Redirect Guard (app_router.dart:218-253)
RATING: CLEAN

- `_redirectGuard` correctly uses `ProviderScope.containerOf(context)` for GoRouter context
- `_isShellRoutePath` correctly excludes `/connection`, `/servers`, `/skills`, `/memory`, `/insights`, `/settings/license`
- Redirect only fires when `ConnectionStatus.idle` AND location is a ShellRoute page
- 2 test groups (idle + connected) in `test/core/router/app_router_test.dart` — all pass
- No race condition with disconnect navigation
- No stale context issue — `containerOf` resolves at call time

### Tailscale/CGNAT Range (committed: 542e85a)
RATING: CLEAN

- `isLocalNetwork` now includes `100.64.0.0/10` (Tailscale / CGNAT)
- 2 tests added: detects 100.64.x.x range, rejects 100.x.x.x outside range
- All 437 tests pass including the 2 new Tailscale tests

====================================================================

## STILL OPEN

### BUG-002-P1: Missing "Disconnect & Exit" Feature (Danger Zone)
STATUS: NOT IMPLEMENTED | SEVERITY: HIGH
CHILD TASK: t_b9ad8d83 (todo, assigned to flutter-state-engineer)

Evidence unchanged from Cycle #3:
- settings_screen.dart Danger Zone: "Delete All Local Data" and "Reset to Defaults" only
- AppStrings.disconnectExit — 0 references outside app_strings.dart
- AppStrings.switchServer — 0 references outside app_strings.dart

### Persistent Technical Debt
- LL-010: API contract spec drift — 06_api_contract.md missing /v1/memory, /v1/insights, /v1/workspace
- LL-011: Two ApiEndpoints files (core/api/ vs core/constants/)
- LL-012: Security spec minimal — 7 of 10 vectors missing

====================================================================

## LL-NNN CROSS-REFERENCE (ALL 30 LESSONS)

All 30 LL lessons remain CLEAN where applicable:
- LL-022 (API key redaction guard): `grep "apiKey: *** lib/"` returns 0 matches — GOV-005 enforced
- LL-023 (fake connection state): `selectServer` flow unchanged since fix
- LL-024 (namespace mismatch): Gate 1 in preflight — PASSES
- LL-025 (Isar + ProGuard): `isMinifyEnabled = false` — verified
- LL-027 (cleartext HTTP): `cleartextTrafficPermitted="true"` — verified
- LL-029 (duplicate messages): `_buildHistory()` called BEFORE `state.copyWith()` — verified fixed
- LL-030 (orchestrator governance): No direct code execution from Lead Architect — GOV-001 active
- LL-019 (empty catch blocks): auth_manager.dart catch blocks still have comments but no logging — NOTED (low priority, existing LL)

Governance rules GOV-001 through GOV-005 remain active and enforced.

====================================================================

## PATTERNS DB STATUS

3 auto-patterns from previous scans are now RESOLVED by uncommitted fixes:
- Pattern #16: duplicate_validateUrl → FIXED (delegation pattern)
- Pattern #15: nav_deadend → FIXED (ConnectionScreen + SkillsScreen back buttons)
- Pattern #17: unused_constants → still open (BUG-002-P1)

Suggestion: mark patterns 15 and 16 as inactive/resolved in patterns.db on next SCSI L3 cycle.

====================================================================

## SEVERITY SUMMARY

| Severity | Count | Items |
|----------|-------|-------|
| HIGH     | 1     | BUG-002-P1: Missing Disconnect & Exit |
| MEDIUM   | 3     | API contract drift, duplicate endpoints, unused constants |
| LOW      | 1     | Empty catch blocks lack logging (LL-019, existing) |
| RESOLVED | 3     | _validateUrl duplication, ConnectionScreen dead-end, SkillsScreen dead-end |

====================================================================

## SUGGESTED ACTIONS

1. COMMIT: The 9 uncommitted files represent 3 resolved bugs + router guard implementation.
   All tests pass, analyze is clean — ready for commit with message summarizing the 3 fixes.
2. DISPATCH: t_b9ad8d83 (Disconnect & Exit) is the LAST remaining BUG-002 sub-task.
   Prerequisites are done. State Engineer can start immediately.
3. PATTERN UPDATE: Mark patterns #15 and #16 as resolved in patterns.db.

====================================================================
End of Hunt Report — Cycle #4
