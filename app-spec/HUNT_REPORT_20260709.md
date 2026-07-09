# HUNT REPORT — SCSI Layer 1 Scan
**Date:** 2026-07-09
**Hunter:** flutter-curiosity-hunter (صيّاد)
**Task:** t_016eec23 — Hermex UI Polish Bug Pattern Scan
**Patterns DB:** 13 active patterns queried

## Scope
- `lib/features/tasks/` — 5 files
- `lib/features/chat/` — 7 files
- `lib/core/api/` — 3 files
- `android/app/src/main/AndroidManifest.xml`

## CRITICAL (2)

### C-1: Dead Attachment Button (Known BUG-2)
- **File:** `lib/features/chat/presentation/chat_input.dart:54`
- **Root Cause:** `onPressed: null` on IconButton with comment `// Future feature.`
- **Impact:** Button renders visible but is a complete no-op. User sees attach icon, taps it, nothing happens.
- **Pattern:** LL-AUTO dead button — UI element with null handler
- **Fix In Flight:** TSK-ATTACH (t_eeaf7c65) is assigned

### C-2: Dead Error Dismiss Button (NEW)
- **File:** `lib/features/chat/presentation/chat_screen.dart:234-237`
- **Root Cause:** `GestureDetector.onTap` callback body is EMPTY — just a comment. `ChatNotifier.clearError()` at `chat_provider.dart:408` exists but is never wired.
- **Impact:** User cannot dismiss error banners. X icon renders but does nothing. Error permanently pinned.
- **Pattern:** LL-AUTO dead button — UI element with null/empty handler
- **Fix:** Wire `onTap` to `ref.read(chatProvider.notifier).clearError()`

## MEDIUM (2)

### M-1: Bypassed Shared API Client Provider
- **File:** `lib/features/tasks/providers/task_provider.dart:576`
- **Root Cause:** `taskDetailProvider` creates brand new `ApiClient` + `TaskRepository` per fetch. Shared `resolvedApiClientProvider` unused.
- **Impact:** Resource waste. Config drift risk if shared provider changes.

### M-2: Redundant AuthManager Instantiation (3x)
- **File:** `lib/features/tasks/providers/task_provider.dart:115, 141, 570`
- **Root Cause:** `AuthManager(secureStorage: SecureStorage())` created three separate times.
- **Impact:** Redundant SecureStorage instances. Inconsistent with chat provider pattern.

## LOW (1)

### L-1: Hardcoded Fallback Model ID
- **File:** `lib/features/chat/providers/chat_provider.dart:137`
- **Root Cause:** `selectedModelId: 'hermes-default'` hardcoded when server returns 0 models.
- **Impact:** If fallback ID doesn't match any server model, all sends fail with generic error.

## CLEAN (7 verified safe)
- `task_list_screen.dart` — All 5 states, pull-to-refresh, auto-load
- `task_detail_screen.dart` — Loading/data/error/notFound states, delete confirm
- `task_repository.dart` — Error classification, malformed JSON skip
- `api_client.dart` — validateStatus < 500, interceptor test updated
- `sse_client.dart` — SSE parsing, oversized event rejection
- `network_security_config.xml` — LL-027 FIXED
- `AndroidManifest.xml` — INTERNET permission, cleartext aligned

## Summary
| Severity | Count |
|----------|-------|
| CRITICAL | 2 |
| MEDIUM | 2 |
| LOW | 1 |
| CLEAN | 7 |
