# 🛡️ POST-SCAN CORRECTIONS — Guardian Cycle #7
# Lead Architect verification performed 2026-07-08T01:30
# Against HEAD: d3436e8 (BUG-006 fix)

====================================================================
## CORRECTION SUMMARY
====================================================================

The Guardian's L1/L2 scan ran BEFORE commit d3436e8 was applied. Several
findings were resolved by that commit. Three others were false positives
due to scan heuristics not matching the actual code flow.

| Original Finding | Guardian Severity | Post-Scan Disposition |
|---|---|---|
| M1: BUG-006 dialog text | MEDIUM | ✅ RESOLVED by d3436e8 |
| AV-001: chat_provider L2 | CRITICAL | ❌ FALSE POSITIVE |
| AV-006: auth_manager token expiry | HIGH | ⬇️ DOWNGRADED to LOW |
| N1: workspace null client | MEDIUM | ❌ FALSE POSITIVE |
| C1: dead 404 interceptor | CRITICAL | 🔴 CONFIRMED (complex fix) |
| N2: missing feature flags | MEDIUM | 🔴 CONFIRMED |
| M2: Riverpod disposal race | MEDIUM | 🔴 CONFIRMED |
| N3: session dialog bg color | LOW | 🔴 CONFIRMED |

====================================================================
## FALSE POSITIVES — DETAILED ANALYSIS
====================================================================

### M1: BUG-006 Dialog Text Visibility → RESOLVED ✅
COMMIT: d3436e8 "fix: BUG-006 — AlertDialog text visibility on dark surface"
EVIDENCE:
- app_theme.dart:152-157 — DialogThemeData now has titleTextStyle (headlineSmall
  + textPrimary) and contentTextStyle (bodyMedium + textSecondary)
- settings_screen.dart:394-470 — All 3 Danger Zone dialogs use explicit
  style: Theme.of(ctx).textTheme... with HermesColors.text{Primary,Secondary}
- All text routed through AppStrings constants (DEC-043 compliant)
- WCAG AA verified: title 10.6:1, content 5.1:1

### AV-001: chat_provider.dart copyWith BEFORE _buildHistory → FALSE POSITIVE ❌
Guardian flagged line 634 as "copyWith before _buildHistory (LL-029 pattern)".
ACTUAL CODE:
- sendMessage() at line 378: `final history = _buildHistory()`
- sendMessage() at line 395: `state = state.copyWith(messages: [...])`
  → _buildHistory() is BEFORE copyWith — CORRECT ORDER, no LL-029 risk
- _onStreamDone() at line 634: `state = state.copyWith(messages: ...)`
  → This is the STREAM-DONE handler — has no _buildHistory() call at all
  → Completely unrelated to sendMessage()

### AV-006: auth_manager.dart — no token expiry → DOWNGRADED to LOW ⬇️
AuthManager manages static Bearer API keys, NOT JWTs. There is no token
expiry concept because Hermes Agent uses long-lived API keys. The auth
model is: one API key per server, stored in flutter_secure_storage.
Security note: if the server supports rotating API keys, the client has
no mechanism to discover or handle key rotation. Low priority — most
users connect to a local Hermes instance with a static key.

### N1: workspace_provider — null apiClient → FALSE POSITIVE ❌
Guardian flagged workspace_provider.dart:11 for passing null to repository.
ACTUAL CODE:
- workspace_provider.dart:9-12: `final apiClient = ref.watch(...).valueOrNull`
- workspace_repository.dart:16: `WorkspaceRepository({ApiClient? apiClient})`
  → Constructor ACCEPTS null
- workspace_repository.dart:24-26: `if (client == null) { return []; }`
  → getDirectoryContents gracefully returns empty list on null
- workspace_repository.dart:51-53: `if (client == null) { throw ConnectionException(...) }`
  → getFileContent throws typed exception on null

Both code paths handle null correctly. Compare with insights_provider
(lines 20-24) and memory_provider (lines 22-26) which use identical pattern.

====================================================================
## CONFIRMED ISSUES
====================================================================

### C1: Dead 404 Interceptor — CRITICAL 🔴 (3+ cycles unfixed)
FILE: lib/core/api/api_client.dart:80-121 (convenience methods)
      lib/core/api/api_client.dart:295-311 (_ErrorClassifierInterceptor)
AFFECTED: memory_provider.dart:42, insights_provider.dart:42,
           task_repository.dart (6x catch blocks), server_repository.dart:213

ROOT CAUSE: Dio's interceptor `handler.next()` REQUIRES a `DioException`.
You cannot pass `handler.next(exception)` — Dio expects the original error
object. The current _ErrorClassifierInterceptor at line 297-309 classifies
correctly but then MUST pass `handler.next(error)` (raw DioException) because
Dio's API requires it. This means providers that catch `ClientException` or
`ApiException` from convenience methods NEVER see the classified type.

CORRECT FIX (multi-file coordinated change):
1. Wrap ApiClient convenience methods (get/post/put/delete at lines 80-121)
   with try/on DioException catch that calls _classifyError and throws
   the typed ApiException.
2. Remove _ErrorClassifierInterceptor (lines 295-311) — no longer needed
   since classification moves to convenience methods.
3. Change memory_provider.dart:42 and insights_provider.dart:42 from
   `e is ClientException` to `e is ApiException` (match new throw type).
4. Change task_repository.dart (6 methods) from `on DioException catch` to
   `on ApiException catch` and remove local _classifyError calls (lines
   44-183) — ApiClient now classifies before throwing.
5. Change server_repository.dart:213 from `on DioException catch` to
   `on ApiException catch` and update _mapDioError to accept ApiException.
6. Verify session_list_screen.dart:540,560 (is DioException checks) — these
   catch raw Dio from repo methods that may now throw ApiException.

AFFECTED FILES (full list):
- lib/core/api/api_client.dart
- lib/features/memory/providers/memory_provider.dart
- lib/features/insights/providers/insights_provider.dart
- lib/features/tasks/data/task_repository.dart
- lib/features/connection/data/server_repository.dart
- lib/features/sessions/presentation/session_list_screen.dart (verify)

### N2: Missing FeatureFlags for Memory/Workspace — MEDIUM 🔴
FILE: lib/core/constants/route_paths.dart:5-12
      lib/core/router/app_router.dart:115-125

FeatureFlags currently has ONLY `insightsEnabled = false`. Memory and
Workspace routes are wired unconditionally in app_router.dart even though
both endpoints return 404 from gateway (port 8642). They're dashboard APIs
on port 9119 (LL-031). Providers degrade gracefully but users navigate to
empty screens with no explanation.

FIX:
1. Add `memoryEnabled = false` and `workspaceEnabled = false` to FeatureFlags
2. Gate Memory and Workspace GoRoute entries with `if (FeatureFlags.memoryEnabled)`
   and `if (FeatureFlags.workspaceEnabled)` in app_router.dart:118-122
3. Optionally gate Settings navigation items for Memory/Workspace

### M2: Riverpod Disposal Race in skills_provider_test — MEDIUM 🔴
FILE: test/features/skills/providers/skills_provider_test.dart:169
CAUSE: skillsRepositoryProvider → resolvedApiClientProvider →
  connectionProvider → async _loadServers() → MethodChannel call.
  Container.dispose() runs before the async chain completes.
ERROR: "This test failed after it had already completed."

FIX: Add `addTearDown(() => container.dispose())` or use ProviderScope
  overrides to mock connectionProvider, preventing the MethodChannel call.

### N3: session_list_screen Delete Dialog Missing backgroundColor — LOW 🔴
FILE: lib/features/sessions/presentation/session_list_screen.dart:598-625
Line 601: AlertDialog has NO backgroundColor parameter.
All Danger Zone dialogs in settings_screen.dart explicitly set
`backgroundColor: HermesColors.surface`. This dialog lets Flutter default.

NOTE: Text visibility is NOT an issue here — commit d3436e8 added global
DialogThemeData.titleTextStyle/contentTextStyle which applies to ALL
AlertDialogs. This is a visual consistency issue only.

FIX: Add `backgroundColor: HermesColors.surface` at line 601.

====================================================================
## RESOLVED THIS CYCLE
====================================================================

- R1: BUG-002-P1 Disconnect & Exit ✅
- R2: LL-032 Profile name dynamic ✅
- R3: LL-029 duplicate messages verified clean ✅
- M1: BUG-006 dialog text visibility ✅ (d3436e8)

====================================================================
## FINAL TALLY (POST-SCAN)
====================================================================

| Severity | Count | Items |
|----------|-------|-------|
| CRITICAL | 1     | C1: dead 404 interceptor (complex fix, 6+ files) |
| MEDIUM   | 2     | N2: feature flags, M2: Riverpod disposal race |
| LOW      | 2     | AV-006: token expiry not applicable, N3: dialog bg color |

====================================================================
End of Post-Scan Corrections
