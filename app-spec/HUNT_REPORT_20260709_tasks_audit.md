# SCSI L1 HUNT REPORT — Cron Jobs Display Area Audit
**Timestamp:** 2026-07-09T02:00:00+03:00
**Hunt ID:** t_b301ce2e
**Files Scanned:** 3 primary + 5 dependency
**Patterns DB Cross-Referenced:** 15 patterns checked
**Findings:** 2 CRITICAL, 2 MEDIUM, 3 LOW

---

## Files Audited

| File | Lines | Role |
|------|-------|------|
| `lib/features/tasks/presentation/task_list_screen.dart` | 620 | UI display — job cards, status badges, action chips |
| `lib/features/tasks/data/task_repository.dart` | 246 | API layer — CRUD + actions against Hermes Agent API |
| `lib/features/tasks/providers/task_provider.dart` | 579 | Riverpod state management — TaskListNotifier + providers |
| `lib/models/cron_job.dart` | 72 | Data model — freezed CronJob with JSON serialization |
| `lib/core/api/api_client.dart` | 280 | HTTP client — Dio configuration, interceptors |
| `lib/core/api/endpoints.dart` | 50 | API route constants |
| `lib/core/api/api_exception.dart` | 71 | Typed exception hierarchy |
| `lib/core/auth/auth_manager.dart` | 136 | Auth token management |

---

## CRITICAL FINDINGS

### C-1: Unsafe Map Cast on API Job Response — Hard Crash Path

**WHAT:** Four locations in `task_repository.dart` perform an unchecked cast on `response['job']` that throws `_CastError` (or `TypeError`) if the API returns any unexpected shape — null, missing key, or wrong type.

**WHERE:**
- `task_repository.dart:62` — `getById()`: `final jobData = response['job'] as Map<String, dynamic>;`
- `task_repository.dart:102` — `create()`: `final jobData = response['job'] as Map<String, dynamic>;`
- `task_repository.dart:147` — `update()`: `final jobData = response['job'] as Map<String, dynamic>;`
- `task_repository.dart:187` — `runNow()`: `final jobData = response['job'] as Map<String, dynamic>;`

**WHY:** The `ApiClient.get()` / `post()` / `patch()` methods return `response.data ?? {}`. If:
- The API returns `{}` (empty object), then `response['job']` returns `null`, and `null as Map<String, dynamic>` throws.
- The API returns `{"job": null}`, same crash.
- The API returns a non-map value, crash.
- A proxy/firewall injects HTML (e.g., captive portal), crash.

The `DioException` catch blocks in each method only handle connection-level errors (timeout, connection error, bad response status >= 500). A 200 OK with a malformed body passes through and crashes in the cast.

**SEVERITY:** CRITICAL — Unhandled exception in production. Any API version drift, intermediate proxy, or server-side change can crash the tasks feature entirely.

**Pattern match:** None in DB yet. This is a new pattern class: `UNSAFE_RESPONSE_CAST`.

**Suggested gate:**
```bash
# GREP: every `response['<key>'] as Map<String, dynamic>` without prior null check
grep -n "response\[.*\]\s*as\s*Map<String,\s*dynamic>" lib/features/tasks/data/task_repository.dart
```
Fix: Add null-guard before cast or use `(response['job'] as Map<String, dynamic>?)` with `??` fallback.

---

### C-2: Server Response Body Leaked to User-Facing Error Messages

**WHAT:** When any API call fails, the full server error response body is included in the `ApiException.toString()` output, which flows directly into `state.errorMessage` and is rendered in the UI at `task_list_screen.dart:159`.

**WHERE:**
- `api_exception.dart:11-12` — `ApiException.toString()` includes `responseBody`
- `task_repository.dart:216-245` — `_classifyError()` captures `error.response?.data?.toString()` as `body` and passes it to exception constructors
- `task_provider.dart:194` — `errorMessage: e.toString()` (also lines 259, 326, 381, 435, 484, 532)
- `task_list_screen.dart:159` — `state.errorMessage!` rendered raw in UI

**WHY:** If the Hermes Agent API Server returns an error response like:
```json
{"error": "E11000 duplicate key error", "collection": "cron_jobs", "stack": "at Collection.ensureIndex (...)"}
```
The entire string is displayed verbatim to the user. This leaks:
- Internal server architecture details (database type, collection names)
- Stack traces
- Potentially sensitive IDs or paths

**SEVERITY:** CRITICAL — Information disclosure. Server internals exposed to end users in a mobile app that talks to potentially self-hosted servers.

**Pattern match:** None in DB. New pattern: `ERROR_BODY_LEAK`.

**Suggested gate:** Audit all `e.toString()` assignments to `errorMessage` in providers. Server exceptions should expose only a sanitized `message`, never the raw `responseBody`.

---

## MEDIUM FINDINGS

### M-1: Direct HermesColors Bypass Theme colorScheme — WCAG AA Contrast Failure

**WHAT:** The tasks feature exclusively uses `HermesColors.textPrimary` (#E6EDF3), `HermesColors.textSecondary`, `HermesColors.textDisabled` etc. instead of `Theme.of(context).colorScheme`.

**WHERE:** `task_list_screen.dart` lines 68, 115, 152, 161, 198-205, 257, 261, 332, 350, 370, 398-407, etc.

**WHY:** In light mode, `HermesColors.textPrimary` (#E6EDF3) on a white background yields a contrast ratio of only ~1.2:1 — far below WCAG AA minimum of 4.5:1. This matches known pattern **LL-AUTO-hardcoded_theme_colors** (MEDIUM). The feature is essentially unreadable in light mode.

**SEVERITY:** MEDIUM — Accessibility failure. Users with visual impairments cannot read job names, schedules, or status badges in light mode.

---

### M-2: No Input Sanitization on Cron Job Fields Before API Transmission

**WHAT:** User input from `task_form_screen.dart` flows directly into the API JSON body without any sanitization, length validation, or character filtering.

**WHERE:**
- `task_form_screen.dart:140-150` — form values extracted and passed to notifier
- `task_repository.dart:90-98` — values added to JSON body map as-is

**WHY:** The following user-controlled fields are sent to the server without sanitization:
- `prompt` (TextFormField, multi-line — no max length enforced)
- `schedule` (TextFormField — validated for cron format but no length limit)
- `name` (TextFormField — no max length)
- `skills` (comma-separated — split and sent as array, no individual length limits)
- `modelProvider`, `modelName`, `deliver` (TextFormFields — no max length)

While the server should validate, the app has no defense-in-depth. A malicious or compromised server could echo back unsanitized content to other clients. Also, excessively long inputs could cause performance issues on the server side (no request body size limit is enforced client-side).

**SEVERITY:** MEDIUM — Defense-in-depth gap. `SecurityLimits` only limits response sizes, not request payloads.

---

## LOW FINDINGS

### L-1: Malformed Job Entries Silently Dropped in Production

**WHERE:** `task_repository.dart:31-42`

In production (`kDebugMode == false`), malformed job entries in the API response are silently skipped with no Crashlytics/analytics event logged. This makes debugging production data issues impossible without reproducing in debug mode.

**SEVERITY:** LOW — Telemetry gap. Does not affect functionality but hampers production debugging.

---

### L-2: Inconsistent clearError Flag on Error States

**WHERE:** `task_provider.dart:168-171`, 231-234, 293, 351, 406

Error states set due to "no server" / "no repo" conditions use `state.copyWith(errorMessage: ...)` without `clearError: true`. While functionally correct (explicit `errorMessage` overrides any prior value), this is inconsistent with loading states (line 175) and error states after try/catch which all use `clearError: true`.

**SEVERITY:** LOW — Cosmetic inconsistency. No functional impact.

---

### L-3: _applyPreset Sets Controller Text Without Triggering Validation

**WHERE:** `task_form_screen.dart:214`

The `_applyPreset` method sets `_scheduleController.text = cron` but does not call `_formKey.currentState!.validate()`. If a preset value were somehow invalid (future code change introducing a bad preset), the field would contain invalid data without visual validation feedback until form submission.

**SEVERITY:** LOW — All current presets (line 204-211) are valid cron expressions. Only a risk if presets are modified in the future.

---

## CLEAN (Verified Safe)

| Area | Reason |
|------|--------|
| `mounted` check after async gap | ✅ `task_list_screen.dart:282` checks `mounted` after `showDialog` |
| Delete confirmation guard | ✅ Dialog confirmation pattern prevents accidental deletes |
| Duplicate submission prevention | ✅ `isBusy` flag prevents double-tap on all actions (lines 221, 283, 341, 396, 451, 498) |
| Duplicate load prevention | ✅ `_loadJobs()` checks `status == loading || isBusy` (line 158) |
| Controller disposal | ✅ All 7 TextEditingControllers disposed properly (lines 69-77) |
| API key handling | ✅ Retrieved from OS-encrypted secure storage, never logged |
| Certificate pinning support | ✅ TOFU pinning via CertificatePinner (api_client.dart:47-54) |
| Response size limits | ✅ _SizeLimitInterceptor enforces SecurityLimits.maxJsonResponseSize (10MB) |
| LL-029 mutation order | ✅ Not applicable — no history/snapshot pattern in task provider |
| LL-024 namespace mismatch | ✅ Not applicable — not an Android build config file |
| LL-025 Isar + ProGuard | ✅ Not applicable — no Isar usage in tasks feature |
| LL-AUTO-duplicate_validateurl | ✅ Not applicable — no URL validation in scope |
| LL-AUTO-nav_deadend | ✅ TaskListScreen is ShellRoute home — no back button needed |

---

## Summary

```
CRITICAL: 2 | MEDIUM: 2 | LOW: 3 | CLEAN: 13
```

### Recommended Triage Order:
1. **C-1 (unsafe cast)** — Fix immediately: add null-guard before each `response['job'] as Map<String, dynamic>`
2. **C-2 (error body leak)** — Strip `responseBody` from user-facing error messages; log it to Crashlytics instead
3. **M-1 (theme colors)** — Defer to next design pass; entire codebase shares this pattern (542 locations)
4. **M-2 (input sanitization)** — Add `maxLength` to TextFormFields and request body size check
5. **L-1/L-2/L-3** — Defer as tech debt
