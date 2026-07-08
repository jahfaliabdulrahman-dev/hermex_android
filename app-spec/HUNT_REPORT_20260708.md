# HUNT REPORT — SCSI L1 Full Scan (Cycle #6)
# hermex_android codebase
# Scan date: 2026-07-08T01:10:00Z (Cycle #6 — 6-Bug Epic Guardian)

====================================================================
SCSI HUNT #6 | files scanned: 115+ | patterns matched: 7/17 | bugs found: 3 (1 CRITICAL, 2 MEDIUM)
====================================================================

## BUILD GATES

[PASS] flutter analyze — 0 issues (CLEAN)
[FAIL] flutter test — 476 passed, 1 FAILED (-1)
  └─ FAILED: `SkillsNotifier — basic access SkillsRepositoryProvider exists and returns non-null`
     File: test/features/skills/providers/skills_provider_test.dart:169
     Error: "This test failed after it had already completed"
     Root cause: `skillsRepositoryProvider` watches `resolvedApiClientProvider` which
     depends on `connectionProvider` triggering async `_loadServers()` (platform channel).
     The ProviderContainer is disposed via `addTearDown` but async work outlives it.
     Fix: Override `resolvedApiClientProvider` or `connectionProvider` in test container.
[INFO] 35 uncommitted files (2833+ insertions, 246 deletions) — all 6 bug fixes + tests

====================================================================

## CYCLE #5 FINDINGS — STATUS UPDATE

### C1: DEAD 404 Handling — NOT FIXED (carried forward)
STATUS: CRITICAL | FILE: api_client.dart:66
Same as Cycle #5. `handler.next(error)` still passes raw DioException instead of
classified ClientException. Both insights_provider.dart:42 and memory_provider.dart:42
have `e is ClientException` checks that will ALWAYS evaluate to false.

Fix: Change `handler.next(error)` → `handler.next(exception)` on line 66.

### M1: BUG-006 Dialog Text — NOT FIXED (carried forward)
STATUS: MEDIUM | FILE: settings_screen.dart:447-545, app_theme.dart:144
Confirmed by QA (t_46067b88). All 3 Danger Zone dialogs still use `const Text(...)`
without explicit `style:`. DialogThemeData still missing `titleTextStyle`/`contentTextStyle`.
Spec exists at app-spec/BUG-006-dialog-text-visibility-spec.md.

### M2: Test pumpAndSettle Timeout — RESOLVED ✅
STATUS: FIXED | By: QA tester (run #207)
Changed `pumpAndSettle()` → `pump()` in settings_screen_test.dart spinner checks.
CircularProgressIndicator animation never settles — pumpAndSettle was wrong call.

====================================================================

## NEW FINDINGS (CYCLE #6)

### N1: skills_provider_test Riverpod Disposal Race
STATUS: MEDIUM | FILE: test/features/skills/providers/skills_provider_test.dart:169

Root cause chain:
  skillsRepositoryProvider (line 10)
    → ref.watch(resolvedApiClientProvider) (line 10)
      → ref.watch(connectionProvider) (api_client_provider.dart:46)
        → ConnectionNotifier.build() → _loadServers() (async platform channel)
          → MethodChannel._invokeMethod (async, outlives test)
    → test completes → container.dispose()
    → async channel work fires after disposal → "test failed after it had already completed"

Fix: Override connectionProvider or resolvedApiClientProvider in the test container
to prevent the async platform channel chain.

====================================================================

## BOARD STATUS — 6-BUG EPIC

| Task ID | Bug | Status | Guardian |
|---------|-----|--------|----------|
| t_3c912589 | BUG-1 Model Selector | DONE | APPROVED (Cycle #5) |
| t_9df6c8ca | BUG-2 Sessions | DONE | Auto-completed |
| t_5b328773 | BUG-3 Workspace | DONE | Feature-gated ADR-010 |
| t_491b6092 | BUG-4 Profile Name | DONE | APPROVED (Cycle #5) |
| t_68176d76 | BUG-5 Memory | DONE | Graceful 404 |
| t_e4fa70fd | BUG-5 Skills | DONE | Auth classification |
| t_601753a4 | Zero-Trust Audit | DONE | CONDITIONAL PASS (3 medium) |
| t_46067b88 | QA Validation | BLOCKED | BUG-006 not implemented |
| t_3785973f | BUG-6 Spec | DONE | Design spec delivered |
| (no task) | BUG-6 Implementation | MISSING | Needs creation |

====================================================================

## DEPENDENCY VERIFICATION (LL-037)

- All 5 implemented bugs reference valid API endpoints (verified in prior cycles)
- BUG-005 endpoints (/v1/memory, /v1/insights) correctly documented as dashboard-only
- C1 bug means 404 handling is structurally dead — dependency chain verification PASS
  but runtime behavior FAIL

====================================================================

## LL-NNN CROSS-REFERENCE

- LL-029 (duplicate messages): `_buildHistory()` called BEFORE state.copyWith() — verified clean
- LL-033 (endpoint verification): Contract updated with ⚠️ — BUT handlers dead (C1)
- LL-037 (dependency verification): THIS SCAN — interceptor propagation bug still open

====================================================================

## SEVERITY SUMMARY

| Severity | Count | Items |
|----------|-------|-------|
| CRITICAL | 1     | C1: Dead 404 interceptor (carried forward from Cycle #5) |
| MEDIUM   | 2     | M1: BUG-006 dialog text (carried forward), N1: skills_provider Riverpod race |
| RESOLVED | 1     | M2: test pumpAndSettle timeout (fixed by QA) |

====================================================================

## SUGGESTED ACTIONS

1. FIX (C1): Change `handler.next(error)` → `handler.next(exception)` in api_client.dart:66
2. FIX (M1): Implement BUG-006 per app-spec/BUG-006-dialog-text-visibility-spec.md
3. FIX (N1): Override connectionProvider in skills_provider_test.dart:166 container
4. CREATE: BUG-006 implementation task (spec exists, code not written)
5. BLOCK QA (t_46067b88) until BUG-006 implemented

====================================================================
End of Hunt Report — Cycle #6
