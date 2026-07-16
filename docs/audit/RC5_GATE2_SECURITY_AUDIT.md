============================================================
ZERO-TRUST SECURITY AUDIT REPORT — RC5 (GATE 2/6)
============================================================
Project: hermex_android
Branch:  epic/rc4-polish (HEAD: 4998d31)
Date:    2026-07-11
Auditor: flutter-zero-trust-auditor
Profile: Red Team — Hostile Auditor

VERDICT: REJECT — 2 CRITICAL, 1 HIGH, 3 MEDIUM
============================================================

────────────────────────────────────────────────────────────
  BASELINE VERIFICATION (REG-3 + REG-4)
────────────────────────────────────────────────────────────

REG-3: ApiException.toString() Hardening
  File: lib/core/api/api_exception.dart

  PASS ✓  toString() returns ONLY "Request failed (status: N)"
           No responseBody, no message, no diagnostic data exposed.
           Line 16-22 verified safe.

  PASS ✓  toDebugString() is the ONLY channel for full diagnostics.
           Includes runtimeType, message, statusCode, responseBody.
           Only called from api_client.dart:64 inside debugPrint guard.
           Line 26-35 verified.

  PASS ✓  PayloadTooLargeException.toString() returns only
           "Request failed (payload too large)" — no byte counts.
           Line 78-79 verified.

  PASS ✓  All 6 exception subclasses pass responseBody to super but
           never expose it in toString().

  PASS ✓  Security test at test/core/api/api_client_security_test.dart:29-46
           validates toString() safety and toDebugString() completeness.

REG-4: _sanitizeError() Wiring
  File: lib/features/tasks/providers/task_provider.dart

  PASS ✓  _sanitizeError() exists at line 86.
  PASS ✓  Wired in all 7 error paths:
           [✓] _loadJobs()   — line 210
           [✓] createJob()   — line 275
           [✓] updateJob()   — line 342
           [✓] deleteJob()   — line 397
           [✓] runJobNow()   — line 452
           [✓] pauseJob()    — line 501
           [✓] resumeJob()   — line 548

Hard Delete Audit
  PASS ✓  No server-side hard delete violations.
           session_repository.dart:226-243 — local Isar cache clear (legitimate)
           api_client.dart:142-147 — HTTP DELETE to server (server-owned)
           secure_storage.dart:64,117 — local key-value store delete (normal)

────────────────────────────────────────────────────────────
  FINDINGS
────────────────────────────────────────────────────────────

============================================================
FINDING AUD-RC5-001 — CRITICAL
============================================================

Title:    Raw DioException Propagates to UI — 4 Repositories Missing
          ApiException Wrapping (session, workspace, skills, memory)

Severity: CRITICAL

Root Cause:
  ApiClient error interceptor (lib/core/api/api_client.dart:59-68)
  calls _classifyError() ONLY for debug logging and passes the
  ORIGINAL DioException to handler.next(error).

  Exception hierarchy:
    api_exception.dart:
      toString() → "Request failed (status: N)"   [SAFE]
      toDebugString() → full diagnostic data        [DEBUG-ONLY]

  BUT: DioException.toString() from package:dio
       INCLUDES message, type, stackTrace, AND response data
       including response body in error text.

Affected Repositories (NO DioException catch):

  • SessionRepository    (lib/features/sessions/data/session_repository.dart)
    → All methods call _apiClient without DioException wrapping.
    → Throws raw DioException on network/auth/server errors.

  • WorkspaceRepository  (lib/features/workspace/data/workspace_repository.dart)
    → getDirectoryContents() and getFileContent() no DioException catch.
    → Throws raw DioException on network failures.

  • SkillsRepository     (lib/features/skills/data/skills_repository.dart)
    → getSkills() no DioException catch.
    → Throws raw DioException (despite doc saying "Throws [ApiException]").

  • MemoryProvider       (lib/features/memory/providers/memory_provider.dart)
    → Catches all errors and wraps in Exception('Failed to load: $e')
    → BUT $e calls .toString() on raw DioException, embedding it in the
      Exception message — no real sanitization.

Affected UI Screens (all call error.toString()):

  • session_detail_screen.dart:84   — from sessionDetailProvider
  • session_list_screen.dart:171    — from sessionListProvider
  • workspace_screen.dart:249,313   — from fileContentProvider / directoryContentsProvider
  • skills_screen.dart:267          — from skillsListProvider
  • memory_screen.dart:86           — from memoryListProvider
  • insights_screen.dart:51         — from insightsProvider (needs separate check)
  • task_detail_screen.dart:632     — from taskDetailProvider (SAFE — task_repository wraps)

Attack Path:
  1. Attacker-controlled Hermes Agent API server returns error responses
  2. ApiClient receives DioException with response body in error.response.data
  3. Session/Workspace/Skills repository does NOT wrap in ApiException
  4. Raw DioException propagates to UI via AsyncValue error handler
  5. UI renders error.toString() — including server response body
  6. Malicious server embeds phishing links, false diagnostics, or
     crafted messages in response body that appear in the app UI

Contrast — TaskRepository (correct):
  task_repository.dart:48-54: on DioException catch (e) → throw _classifyError(e)
  → ApiException toString() → "Request failed (status: 500)" — SAFE

Required Fix:
  Option A (preferred): Fix ApiClient interceptor to throw ApiException
    instead of passing DioException through:

    InterceptorsWrapper(
      onError: (error, handler) {
        final exception = _classifyError(error);
        if (kDebugMode) { debugPrint(...); }
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: exception,      // ← ApiException IS the error
            type: error.type,
            message: exception.toString(),
          ),
        );
      },
    );

  Option B: Add DioException → ApiException wrapping in all 4 affected
    repositories (session, workspace, skills, memory).

  Option C: Centralized sanitization in a helper, used by all UI screens
    before calling error.toString().

Impact:
  Server response body data (HTML, JSON, error messages) appears verbatim
  in the Hermex Android UI. Enables:
  - Server impersonation via crafted error pages in the app
  - Data leakage from error response bodies
  - Social engineering via error messages
  - Violates "backend is source of truth" contract (server poisons client)

Retest Method:
  1. Configure app to connect to a mock Hermes server that returns 500
     errors with custom body: {"error": "SECRET_LEAK_TEST"}
  2. Navigate to Sessions, Workspace, Skills, and Memory screens
  3. Confirm error banners show ONLY "Request failed (status: 500)" or
     a generic message — NOT "SECRET_LEAK_TEST"

============================================================
FINDING AUD-RC5-002 — CRITICAL
============================================================

Title:    Chat Stream SSE Error Leak — Raw Error Details in Chat Bubble

Severity: CRITICAL

Evidence:
  File: lib/features/chat/providers/chat_provider.dart:525
    final errorText = error is String ? error : error.toString();
    messages.add(ChatMessage(
      role: 'system',
      content: 'Error: $errorText',
    ));

  File: lib/features/chat/providers/stream_provider.dart:84
    message: error.toString(),

  The 'error' from the SSE stream could be:
  - StreamException (wrapped by sse_client.dart:115, inherits ApiException) — SAFE
  - Raw DioException if stream setup fails before StreamException wrapping — UNSAFE
  - Any other stream-level error (SocketException, FormatException, etc.) — UNSAFE

  The error text is then rendered in a ChatMessage with role='system'
  displayed in the chat bubble UI.

Attack Path:
  1. Malicious server sends malformed SSE events that trigger stream errors
  2. Stream error propagates to stream_provider onError handler
  3. error.toString() may include partial server response data
  4. Error text is embedded in ChatMessage and rendered in chat UI
  5. User sees potentially malicious content in chat bubbles

Required Fix:
  Apply _sanitizeError() or equivalent to stream error before rendering.
  In chat_provider.dart, ensure errorText extraction uses safe toString():
    final errorText = error is ApiException ? error.toString() : 'Stream error';

Impact:
  Chat bubbles display raw error data including potentially malicious
  server-controlled content. Chat is the primary interaction surface.

Retest Method:
  1. Connect to mock server that sends corrupt SSE data after connection
  2. Verify chat error bubble shows generic "Stream error" not raw data

============================================================
FINDING AUD-RC5-003 — HIGH
============================================================

Title:    SessionsNotifier — 7 Error Paths Use Unsanitized String
          Interpolation

Severity: HIGH

Evidence:
  File: lib/features/sessions/providers/session_provider.dart
  Line 195:  errorMessage: 'Failed to create session: $e',
  Line 247:  errorMessage: 'Failed to rename session: $e',
  Line 298:  errorMessage: 'Failed to delete session: $e',
  Line 331:  errorMessage: 'Failed to update session: $e',
  Line 367:  errorMessage: 'Failed to update session: $e',
  Line 413:  errorMessage: 'Failed to fork session: $e',

  If 'e' is an ApiException, $e calls safe toString() → "Request failed (status: N)"
  If 'e' is a raw DioException (current state per AUD-RC5-001), $e leaks.

  Even after AUD-RC5-001 is fixed, non-ApiException errors (StateError,
  FormatException, IsarError) flow unsanitized through this path.

  Contrast with task_provider.dart which uses _sanitizeError() in all
  7 mutation paths.

Required Fix:
  Add _sanitizeError() to SessionsNotifier and use in all catch blocks.
  Follow the pattern from task_provider.dart:86-89.

Impact:
  Non-ApiException errors in session operations expose internal error
  details to UI error messages.

Retest Method:
  Trigger session creation with invalid server config; verify error
  message is generic, not raw exception text.

============================================================
FINDING AUD-RC5-004 — MEDIUM
============================================================

Title:    _sanitizeError Returns e.message Instead of toString()

Severity: MEDIUM

Evidence:
  File: lib/features/tasks/providers/task_provider.dart:86-89
    String _sanitizeError(Object e) {
      if (e is ApiException) return e.message;
      return e.toString();
    }

  e.message is the raw constructor parameter. For ApiException created by
  _classifyError, this is `error.message ?? 'Unknown error'` — the
  DioException error message like "Connection refused", "Connection timed out".

  While typically less sensitive than responseBody, these messages can
  reveal network topology details (hostnames, IP fragments) that the
  hardened toString() ("Request failed (status: N)") would hide.

  Also: non-ApiException fallback `e.toString()` leaks raw error data.

Required Fix:
    String _sanitizeError(Object e) {
      if (e is ApiException) return e.toString();  // ← use safe toString()
      return 'An unexpected error occurred';        // ← generic fallback
    }

Impact: LOW — network-level details exposed to UI, no server response data.

============================================================
FINDING AUD-RC5-005 — MEDIUM
============================================================

Title:    ApiClient Error Interceptor Architecture Gap

Severity: MEDIUM (Enabler for CRITICAL AUD-RC5-001)

Evidence:
  File: lib/core/api/api_client.dart:59-68
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        final exception = _classifyError(error);
        if (kDebugMode) {
          debugPrint('=== HERMEX DEBUG: ApiClient error — ${exception.toDebugString()} ===');
        }
        handler.next(error);  // ← passes ORIGINAL DioException, not ApiException
      },
    ));

  _classifyError() creates the correct ApiException subclass but the
  result is used ONLY for debug logging. The intercepted DioException
  propagates unchanged to all consumers.

  This forces every repository to implement its own DioException → ApiException
  wrapping (as task_repository correctly does). Repositories that don't
  (session, workspace, skills, memory) leak raw DioException.

Required Fix:
  Replace handler.next(error) with a mechanism that throws the ApiException.
  See AUD-RC5-001 Option A for the fix.

Impact:
  Root cause of AUD-RC5-001. Without this fix, every new repository added
  to the project is at risk of the same vulnerability.

============================================================
FINDING AUD-RC5-006 — MEDIUM
============================================================

Title:    Workspace File Content Fallback Leaks Raw JSON

Severity: MEDIUM

Evidence:
  File: lib/features/workspace/data/workspace_repository.dart:73
    return json.toString();

  When the API response for a file path doesn't match the expected
  String/List shapes, the fallback returns the entire JSON as a string
  via json.toString(). This raw API response is then displayed as file
  content in the workspace preview UI.

  While this is a legitimate fallback for unexpected API shapes, it
  means malformed API responses could dump raw JSON into the file
  preview pane.

Required Fix:
  Replace with a safe default:
    throw ClientException('Unexpected response format for file content');

Impact:
  Raw API response JSON rendered in workspace file preview if server
  returns unexpected format.

============================================================
────────────────────────────────────────────────────────────
  BLACK SWAN PROBE — RC5
────────────────────────────────────────────────────────────

Black Swan Probe #1
  Feature:  FT-TASKS (task list mutations)
  Scenario: User rapidly taps "Pause" then "Resume" before pause
            request completes. Pause's try block starts, then
            resume's try block starts before pause state updates.
  Risk:     isBusy guard (task_provider.dart:237,299) should block
            second mutation. But the guard is local state — if the
            HTTP request is in-flight and state.isBusy is already
            set, second tap is blocked. Passes basic test.
  Verdict:  PASS — isBusy guard exists in all 7 mutation methods.

Black Swan Probe #2
  Feature:  FT-SESSIONS (session delete + navigation)
  Scenario: User deletes a session from the list, but the HTTP
            DELETE succeeds while the detail screen is still open
            for that same session ID. User is viewing stale data
            that no longer exists on the server.
  Risk:     sessionDetailProvider fetches by ID. If the session
            was deleted, API returns 404, which gets wrapped as
            ClientException (if DioException catch exists — currently
            doesn't per AUD-RC5-001). UI shows error state.
  Verdict:  MEDIUM — Race condition between delete and detail view.
            No data corruption but UX degradation. Mitigated once
            AUD-RC5-001 is fixed (error will show safe message).

────────────────────────────────────────────────────────────
  SCOPE CREEP DETECTION
────────────────────────────────────────────────────────────

No scope creep violations detected. All audited code aligns with
PRD-defined features (sessions, tasks, workspace, skills, memory,
chat, insights).

────────────────────────────────────────────────────────────
  SUMMARY
────────────────────────────────────────────────────────────

REG-3 (ApiException.toString()):    PASS ✓
REG-3 (toDebugString() only):       PASS ✓
REG-4 (_sanitizeError wiring):      PASS ✓
Hard delete audit:                  PASS ✓

Systemic gap:                       2 CRITICAL, 1 HIGH, 3 MEDIUM

Blocking issues:
  AUD-RC5-001: 4 repositories leak raw DioException to UI
  AUD-RC5-002: Chat stream errors leak to chat bubbles

RESULT: REJECT — Cannot pass gate until AUD-RC5-001 and AUD-RC5-002
are resolved. REG-3 and REG-4 specific fixes are correct but the
surrounding architecture leaves 4+ data exposure paths unaddressed.

────────────────────────────────────────────────────────────
  EVIDENCE INDEX
────────────────────────────────────────────────────────────

Files read and verified:
  ✓ lib/core/api/api_exception.dart         (REG-3 pass)
  ✓ lib/core/api/api_client.dart            (AUD-RC5-005)
  ✓ lib/features/tasks/providers/task_provider.dart (REG-4 pass)
  ✓ lib/features/tasks/data/task_repository.dart     (reference — correct pattern)
  ✓ lib/features/sessions/data/session_repository.dart (AUD-RC5-001)
  ✓ lib/features/sessions/providers/session_provider.dart (AUD-RC5-003)
  ✓ lib/features/sessions/presentation/session_detail_screen.dart
  ✓ lib/features/sessions/presentation/session_list_screen.dart
  ✓ lib/features/workspace/data/workspace_repository.dart (AUD-RC5-001,006)
  ✓ lib/features/workspace/presentation/workspace_screen.dart
  ✓ lib/features/skills/data/skills_repository.dart     (AUD-RC5-001)
  ✓ lib/features/skills/presentation/skills_screen.dart
  ✓ lib/features/memory/providers/memory_provider.dart  (AUD-RC5-001)
  ✓ lib/features/memory/presentation/memory_screen.dart
  ✓ lib/features/chat/providers/chat_provider.dart      (AUD-RC5-002)
  ✓ lib/features/chat/providers/stream_provider.dart     (AUD-RC5-002)
  ✓ lib/features/insights/presentation/insights_screen.dart
  ✓ lib/features/tasks/presentation/task_detail_screen.dart
  ✓ test/core/api/api_client_security_test.dart          (REG-3 tests)
