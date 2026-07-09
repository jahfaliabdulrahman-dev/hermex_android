# HUNT REPORT — Tasks Feature Scan
**Date:** 2026-07-09
**Hunter:** flutter-curiosity-hunter (SCSI L1)
**Scope:** `lib/features/tasks/` — task_list_screen.dart (620L), task_repository.dart (246L), task_provider.dart (580L)
**Patterns DB:** 17 entries cross-referenced

---

## RESULTS SUMMARY

| Severity | Count | Description |
|----------|-------|-------------|
| CRITICAL | 1 | Unsafe API response cast — TypeError bypasses error handling |
| MEDIUM   | 1 | Hardcoded theme colors — 39 locations |
| LOW      | 2 | Non-DioException error propagation, excessive debug logging |
| PASS     | 13 | Patterns checked, not found or safely mitigated |

---

## CRITICAL FINDINGS

### C-1: Unsafe `response['job'] as Map<String, dynamic>` — TypeError Bypass

**Pattern:** LL-AUTO-unsafe_response_cast
**File:** `lib/features/tasks/data/task_repository.dart`
**Lines:** 62, 102, 147, 187
**Severity:** CRITICAL
**Category:** DATA_INTEGRITY

**Code (all 4 locations follow same pattern):**
```dart
// Line 62 — getById():
final jobData = response['job'] as Map<String, dynamic>;

// Line 102 — create():
final jobData = response['job'] as Map<String, dynamic>;

// Line 147 — update():
final jobData = response['job'] as Map<String, dynamic>;

// Line 187 — runNow():
final jobData = response['job'] as Map<String, dynamic>;
```

**Root Cause:**
The cast `as Map<String, dynamic>` is non-nullable. If the Hermes API Server returns:
- `{"job": null}` → `TypeError: Null is not a subtype of Map<String, dynamic>`
- `{}` (empty object, key missing) → `TypeError: Null is not a subtype of Map<String, dynamic>`

This TypeError is NOT a DioException, so it **bypasses** the `on DioException catch (e)` handler entirely. The raw TypeError propagates to `task_provider.dart` where `catch (e)` captures it and sets `errorMessage: e.toString()`, resulting in UI display of raw Dart type errors like:

> "type 'Null' is not a subtype of type 'Map<String, dynamic>' in type cast"

**Impact:**
- Users see raw Dart runtime errors in the UI instead of friendly messages
- Can happen during normal API behavior (e.g., server restart mid-request returns empty body)
- Affects: getById, create, update, runNow operations

**Contrast with safe pattern (line 29):**
```dart
final jobsList = response['jobs'] as List<dynamic>? ?? [];
```
The `?` (nullable cast) + `?? []` (null-coalescing) pattern handles null safely.

**Suggested Fix:**
```dart
final jobData = response['job'] as Map<String, dynamic>?;
if (jobData == null) {
  throw ServerException('Invalid server response: missing job data');
}
return CronJob.fromJson(jobData);
```

---

## MEDIUM FINDINGS

### M-1: Hardcoded HermesColors Bypass Theme ColorScheme

**Pattern:** LL-AUTO-hardcoded_theme_colors
**File:** `lib/features/tasks/presentation/task_list_screen.dart`
**Instances:** 39
**Severity:** MEDIUM
**Category:** UI_RENDERING

**Sample locations:**
- Line 68: `color: HermesColors.textPrimary`
- Line 78: `backgroundColor: HermesColors.cyan`
- Line 110: `color: HermesColors.textSecondary.withValues(alpha: 0.5)`
- Line 146: `color: HermesColors.error.withValues(alpha: 0.7)`
- (35 more throughout _JobCard, _StatusBadge, _ActionChip, _JobCardSkeleton)

**Root Cause:**
Widgets use `HermesColors.*` constants directly instead of `Theme.of(context).colorScheme.*`. In light mode, `HermesColors.textPrimary` (#E6EDF3 on white) yields 1.2:1 contrast ratio — fails WCAG AA minimum of 4.5:1.

**Impact:**
- Light mode: text nearly invisible against white background
- Dark/light theme switching does not propagate to these hardcoded values
- Codebase-wide issue (542 locations in prior scan)

---

## LOW FINDINGS

### L-1: Non-DioException Errors Propagate Uncaught from Repository

**File:** `lib/features/tasks/data/task_repository.dart`
**Lines:** 62, 102, 147, 187
**Severity:** LOW

**Root Cause:**
The `as Map<String, dynamic>` cast and `CronJob.fromJson()` call are outside the `on DioException` handler. Any FormatException, TypeError, or other non-DioException propagates as raw Dart exception to the provider's generic `catch (e)` block, displaying raw error text in UI.

**Impact:** Degraded UX when unexpected server responses occur. Adjacent to C-1 — fixing C-1 resolves this too.

### L-2: Excessive Debug Logging in Release-Adjacent Code

**File:** `lib/features/tasks/data/task_repository.dart`
**Instances:** 15 `if (kDebugMode) debugPrint(...)` calls
**Severity:** LOW

**Data logged:** Job IDs, prompts (full text), schedule strings, names, DioException details.
**Risk:** Debug builds can be installed on real devices (Android debug APKs, iOS dev builds). Logs are visible via `adb logcat` / Console.app by any process with read permissions. Job prompts may contain sensitive data (API keys in cron job configs, personal automation instructions).
**Mitigation:** `kDebugMode` is false in release builds, but debug builds are common in testing/QA.

---

## PATTERNS CHECKED — PASS (No Findings)

| Pattern | Status | Reason |
|---------|--------|--------|
| LL-AUTO-error_body_leak | PASS | `ApiException.toString()` (api_exception.dart:12) safely excludes `responseBody` — returns only message + status code |
| LL-AUTO-nav_deadend | PASS | TaskListScreen is inside ShellRoute (app_router.dart:46-73) with bottom nav — no back button needed |
| LL-029 / LL-AUTO-duplicate_messages | PASS | No chat message duplication in these files. copyWith is used correctly for state transitions |
| LL-AUTO-state_mutation_order | PASS | No messages array manipulation — task state uses primitive copyWith |
| LL-AUTO-duplicate_validateurl | N/A | Not in tasks feature scope |
| LL-AUTO-google_fonts_network | N/A | Not in tasks feature scope |
| LL-024, LL-025, LL-027, LL-028 | N/A | Android build/infrastructure patterns — not in scope |
| LL-AUTO-colorscheme_asymmetry | N/A | Not in tasks feature scope |
| LL-AUTO-20260707-unused_constants | N/A | Not in tasks feature scope |
| LL-001 | N/A | Initial project setup — archived |

---

## FILE RISK SCORES

| File | Risk | Bugs | Top Category |
|------|------|------|-------------|
| `task_repository.dart` | 0.85 | 1 CRITICAL + 2 LOW | DATA_INTEGRITY |
| `task_provider.dart` | 0.30 | 0 (only consumer of repo errors) | STATE_MANAGEMENT |
| `task_list_screen.dart` | 0.40 | 1 MEDIUM (theme) | UI_RENDERING |

---

## RECOMMENDED GATES

1. **PREFLIGHT gate:** grep for `response\[.job.\] as Map<String, dynamic>` without null guard in `lib/**/data/*.dart` — block if found without `?` nullable cast
2. **PREFLIGHT gate:** For `task_list_screen.dart`, consider a lint rule for `HermesColors.` usage in presentation files (codebase-wide, 542 instances)
