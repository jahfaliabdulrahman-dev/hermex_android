# HUNT REPORT — SCSI L1 Full Scan (Cycle #7)
# hermex_android codebase
# Scan date: 2026-07-08T01:30:00Z (Cycle #7 — 6-Bug Epic Guardian task t_66af7135)

====================================================================
SCSI HUNT #7 | files scanned: 50+ dart files | patterns matched: 8/17 | bugs found: 5 (1 CRITICAL, 4 MEDIUM)
====================================================================

## BUILD GATES

[PASS] flutter analyze — 0 issues (CLEAN)
[FAIL] flutter test — 476 passed, 1 FAILED (-1, same as Cycle #6)
  └─ FAILED: `SkillsNotifier — basic access SkillsRepositoryProvider exists and returns non-null`
     File: test/features/skills/providers/skills_provider_test.dart:169
     Root cause: Riverpod disposal race — async platform channel outlives test container
[INFO] No new commits since Cycle #6. Uncommitted changes still include all 6 bug fixes.

====================================================================

## CARRIED FORWARD (UNCHANGED FROM PRIOR CYCLES)

### C1: Dead 404 Error Classification — CRITICAL
STATUS: STILL OPEN (3rd hunt cycle) | SEVERITY: CRITICAL
FILE: lib/core/api/api_client.dart:66

The onError interceptor calls `_classifyError(error)` which produces a properly
classified exception (e.g., ClientException with statusCode=404), but then passes
the RAW DioException via `handler.next(error)` instead of the classified exception.

```dart
// api_client.dart:59-68
_dio.interceptors.add(InterceptorsWrapper(
  onError: (error, handler) {
    final exception = _classifyError(error);  // <-- Creates classified exception
    // ...debugPrint...
    handler.next(error);                       // <-- BUG: passes raw DioException, not 'exception'
  },
));
```

IMPACT: Both insights_provider.dart:42 and memory_provider.dart:42 have:
```dart
if (e is ClientException && e.statusCode == 404) { ... }
```
This check will ALWAYS evaluate to FALSE because `e` is a raw `DioException`,
never a `ClientException`. The graceful 404 fallback is completely dead code.

AFFECTED FILES:
- lib/core/api/api_client.dart:66 (the bug)
- lib/features/insights/providers/insights_provider.dart:42 (dead fallback)
- lib/features/memory/providers/memory_provider.dart:42 (dead fallback)

FIX: Change `handler.next(error)` → `handler.next(exception)` on line 66.

---

### M1: BUG-006 Dialog Text Visibility — MEDIUM
STATUS: STILL OPEN (2nd hunt cycle) | SEVERITY: MEDIUM (elevated: SAFETY)
FILE: lib/core/theme/app_theme.dart:144-149

DialogThemeData still missing `titleTextStyle` and `contentTextStyle`:
```dart
dialogTheme: DialogThemeData(
  backgroundColor: HermesColors.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
  // MISSING: titleTextStyle, contentTextStyle
),
```

ALL FOUR confirmation dialogs affected:
1. settings_screen.dart:447 — "_showDeleteConfirmation" — "Delete All Data?"
2. settings_screen.dart:472 — "_showResetConfirmation" — "Reset Preferences?"
3. settings_screen.dart:505 — "_showDisconnectConfirmation" — "Disconnect from Server?"
4. session_list_screen.dart:598 — "_showDeleteDialog" — "Delete Session"

Every dialog uses `const Text(...)` without explicit `style:` parameter.
With HermesColors.surface (#161B22) as background, dark text inherits poorly.

---

### M2: skills_provider_test Riverpod Disposal Race — MEDIUM
STATUS: STILL OPEN | FILE: test/features/skills/providers/skills_provider_test.dart:169

Same issue from Cycle #6. skillsRepositoryProvider -> resolvedApiClientProvider ->
connectionProvider -> ConnectionNotifier.build() -> _loadServers() (async platform channel).
Container disposed before async work completes.

====================================================================

## NEW FINDINGS (CYCLE #7)

### N1: Workspace Provider — Null API Client Passed to Repository — MEDIUM
STATUS: NEW | FILE: lib/features/workspace/providers/workspace_provider.dart:9-12

```dart
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  final apiClient = ref.watch(resolvedApiClientProvider).valueOrNull;
  return WorkspaceRepository(apiClient: apiClient);  // <-- apiClient can be null!
});
```

Unlike Memory and Insights providers which check for null and return empty/default,
Workspace creates a repository with a null apiClient. When directoryContentsProvider
or fileContentProvider call into the repository, the null apiClient will cause a
NullPointerException or unexpected behavior.

Memory list provider (comparison): gracefully returns [] when apiClient is null.
Insights provider (comparison): gracefully returns default InsightsData.

FIX: Either add null guard (return empty/error), or make WorkspaceRepository handle
null apiClient gracefully, or gate workspace navigation behind FeatureFlags/ADR-010
like Insights.

---

### N2: Missing Feature Flags for Memory and Workspace — MEDIUM
STATUS: NEW | FILES: route_paths.dart, settings_screen.dart

FeatureFlags.insightsEnabled = false correctly gates Insights navigation.
But Memory and Workspace have NO equivalent feature flag despite both endpoints
returning 404 from the gateway (LL-031: they are dashboard APIs on port 9119).

Memory: has graceful 404 fallback (returns []) but user navigates to an empty screen
with no explanation of WHY it's empty. There IS an AppStrings.memoryRequiresDashboard
constant defined but it's NEVER referenced in any screen code.

Workspace: has no graceful fallback at all — passes null apiClient to repository.

FIX: Add `workspaceEnabled` and `memoryEnabled` to FeatureFlags, gate routes
and settings navigation, show dashboard-required notice when disabled.

---

### N3: session_list_screen.dart Delete Dialog Missing BackgroundColor — LOW
STATUS: NEW | FILE: lib/features/sessions/presentation/session_list_screen.dart:598-627

The `_showDeleteDialog` AlertDialog has NO `backgroundColor` parameter:
```dart
AlertDialog(
  title: const Text(AppStrings.deleteSession),       // no style
  content: const Text(AppStrings.deleteSessionConfirm), // no style
  // MISSING: backgroundColor
)
```

While settings dialogs all explicitly set `backgroundColor: HermesColors.surface`,
this dialog lets Flutter default — may look inconsistent between light/dark themes.

====================================================================

## RESOLVED SINCE CYCLE #5/#6

### R1: BUG-002-P1 — "Disconnect & Exit" in Danger Zone — RESOLVED ✅
STATUS: FIXED | FILE: settings_screen.dart:405-435, 505-550

Evidence:
- Danger Zone now has 3 items (was 2): Delete All, Reset to Defaults, AND Disconnect & Exit
- `_showDisconnectConfirmation()` method (line 505) handles full disconnect flow
- `AppStrings.disconnectExit` referenced at line 411
- Conditional: only shown when `hasActiveServer` (line 405)
- Proper busy state: shows spinner when isBusy, disables button (lines 422-435)
- Navigation: calls context.go(RoutePaths.connection) on success (line 538)
- Error handling: shows SnackBar on disconnect failure (line 534)

---

### R2: LL-032 — Hardcoded 'flutter-state-engineer' Profile Name — RESOLVED ✅
STATUS: FIXED | FILE: settings_screen.dart:253-287

Evidence:
- `grep -r "flutter-state-engineer" lib/` returns ZERO matches
- Profile name now dynamic: `activeServer?.name ?? AppStrings.noServerConnected`
- Subtitle shows "Active Server" when connected, empty string when not
- Uses `connectionState.activeServer` from connectionProvider (live state)

---

### R3: LL-029 — Duplicate Messages State Order — REMAINS CLEAN ✅
STATUS: VERIFIED | FILE: chat_provider.dart:378

`_buildHistory()` called at line 378, BEFORE `state.copyWith(messages: [...])` at
line 395-399. No regression.

====================================================================

## LL-NNN CROSS-REFERENCE (KEY LESSONS)

| LL # | Status | Evidence |
|------|--------|----------|
| LL-010 | OPEN | API contract spec drift — 06_api_contract.md still needs /v1/memory, /v1/insights, /v1/workspace |
| LL-011 | OPEN | Two ApiEndpoints files persist (core/api/ vs core/constants/) |
| LL-019 | LOW | auth_manager.dart empty catch blocks still lack logging |
| LL-022 | CLEAN | "apiKey: ***" grep returns 0 matches |
| LL-023 | CLEAN | selectServer flow now has health check before connected state |
| LL-024 | CLEAN | Gate 1 namespace check PASSES |
| LL-025 | CLEAN | isMinifyEnabled = false verified |
| LL-027 | CLEAN | cleartextTrafficPermitted = "true" verified |
| LL-029 | CLEAN | _buildHistory() BEFORE state.copyWith() — verified |
| LL-031 | PARTIAL | FeatureFlag for Insights only; Memory/Workspace still gated improperly |
| LL-032 | RESOLVED | Profile name now dynamic |
| LL-033 | PARTIAL | Recovery UX exists in ModelSelector + SessionListScreen, but no central AuthErrorBanner |
| LL-034 | OPEN | No capabilitiesProvider implemented — no endpoint discovery before routing |
| LL-035 | OPEN | BUG-006 dialog text — 4 dialogs affected, no fix yet |
| LL-036 | PARTIAL | Connection screen helper text added in model_selector.dart, but connection_screen.dart still unclear |

====================================================================

## SEVERITY SUMMARY

| Severity | Count | Items |
|----------|-------|-------|
| CRITICAL | 1     | C1: Dead 404 interceptor — 3 hunt cycles unfixed |
| MEDIUM   | 4     | M1: BUG-006 dialog text, M2: Riverpod race, N1: Workspace null client, N2: Missing feature flags |
| LOW      | 1     | N3: session_list_screen delete dialog missing backgroundColor |
| RESOLVED | 3     | R1: Disconnect & Exit, R2: Profile name, R3: LL-029 verified |

====================================================================

## SUGGESTED ACTIONS

1. [CRITICAL] Fix api_client.dart:66 — `handler.next(error)` → `handler.next(exception)`
   (ONE-LINE FIX, open for 3 hunt cycles, blocks graceful 404 handling)

2. [MEDIUM] Implement BUG-006 per spec: add titleTextStyle/contentTextStyle to DialogThemeData,
   remove `const` from all 4 dialog Text widgets, add explicit style.

3. [MEDIUM] Add null guard in workspace_provider.dart:9-12 for null apiClient.

4. [MEDIUM] Add `memoryEnabled` and `workspaceEnabled` to FeatureFlags matching
   the `insightsEnabled` pattern.

5. [MEDIUM] Fix skills_provider_test Riverpod disposal race.

6. [LOW] Add `backgroundColor: HermesColors.surface` to session_list_screen delete dialog.

====================================================================
End of Hunt Report — Cycle #7
