# HERMEX-008 RC6 Phase 4: Hostile Re-Audit Report
## Auditor: Zero-Trust Red Team (flutter-zero-trust-auditor)
## Date: 2026-07-16
## Scope: GOAL_RC6_COMPREHENSIVE_REMEDIATION.md — All 5 Attack Vectors

---

# EXECUTIVE VERDICT

**OVERALL: PASS WITH 3 FINDINGS (1 CRITICAL, 1 HIGH, 1 MEDIUM)**

The RC6 fixes are substantially complete. AUD-RC5-001 (raw error leakage) and
AUD-RC5-002 (stream error leakage) are CONFIRMED FIXED across 18 of 20 sites.
Two regressions remain — one from a bypassed ErrorClassifier integration in
task_provider and one from an un-sanitized ClientException catch in chat_provider.
Certificate pinning is uniformly wired. FLAG_SECURE is fully removed. Profile
switching does not leak API keys. Input validation is missing for
reasoningEffort — the UI restricts values but the programmatic API does not.

---

# ATTACK VECTOR RESULTS

## AV1: Raw-Error Leakage (AUD-RC5-001/002 Re-Verification)

### VERDICT: PARTIAL PASS — 2 active findings

### Sites Verified PASS (18/20):

| File | Line | Error Surface | Method | Status |
|------|------|--------------|--------|--------|
| session_provider.dart | 205 | createSession | ErrorClassifier.sanitizeMessage(e) | PASS |
| session_provider.dart | 257 | renameSession | ErrorClassifier.sanitizeMessage(e) | PASS |
| session_provider.dart | 308 | deleteSession | ErrorClassifier.sanitizeMessage(e) | PASS |
| session_provider.dart | 341 | togglePin | ErrorClassifier.sanitizeMessage(e) | PASS |
| session_provider.dart | 377 | toggleArchive | ErrorClassifier.sanitizeMessage(e) | PASS |
| session_provider.dart | 423 | forkSession | ErrorClassifier.sanitizeMessage(e) | PASS |
| chat_provider.dart | 246 | initialize | ErrorClassifier.sanitizeMessage(e) | PASS |
| chat_provider.dart | 278 | loadModels | Static message | PASS |
| chat_provider.dart | 534 | loadHistory (catch-all) | Static message | PASS |
| chat_provider.dart | 640 | _handleStreamError (chat bubble) | ErrorClassifier.sanitizeMessage(error) | PASS |
| chat_provider.dart | 650 | _handleStreamError (errorMessage) | ErrorClassifier.sanitizeMessage(error) | PASS |
| stream_provider.dart | 85 | StreamError event | ErrorClassifier.sanitizeMessage(error) | PASS |
| connection_provider.dart | 307 | selectServer | ErrorClassifier.sanitizeMessage(e) | PASS |
| profile_provider.dart | 158 | createProfile | ErrorClassifier.sanitizeMessage(e) | PASS |
| profile_provider.dart | 214 | updateProfile | ErrorClassifier.sanitizeMessage(e) | PASS |
| profile_provider.dart | 250 | setActiveProfile | ErrorClassifier.sanitizeMessage(e) | PASS |
| profile_provider.dart | 287 | deleteProfile | ErrorClassifier.sanitizeMessage(e) | PASS |
| chat_provider.dart | 508-536 | loadHistory catch block | Typed exception catching (Auth/Connection/Client) | *PARTIAL* |

### Audit Findings:

---

## Audit Finding

### Finding ID
AUD-RC6-001

### Severity
CRITICAL

### Affected Feature
FT-TASKS — Task CRUD error display (all 7 mutation paths)

### Evidence
`lib/features/tasks/providers/task_provider.dart:88-91`

```dart
/// Never expose raw server body to users.
String _sanitizeError(Object e) {
  if (e is ApiException) return e.message;  // ← LEAKS raw data
  return e.toString();                       // ← LEAKS object dump
}
```

This is a BYPASS of the centralized `ErrorClassifier.sanitizeMessage()` which
is the SINGLE SOURCE OF TRUTH per the RC6 spec. The `_sanitizeError` function:

1. Returns `ApiException.message` directly — this is `DioException.message`
   (e.g., "Http status error [404]") — NOT user-friendly, NOT sanitized.
2. Falls back to `e.toString()` for non-ApiException types — can leak
   implementation details, stack traces, and raw exception data.

**Used in 7 catch blocks**: lines 226, 291, 358, 413, 468, 517, 564.

Compare with the CORRECT pattern used everywhere else:
```dart
errorMessage: 'Failed to ...: ${ErrorClassifier.sanitizeMessage(e)}',
```

### Attack Path
1. Trigger any API error (e.g., invalid cron expression, network timeout)
2. The DioException is classified by _classifyError into an ApiException
3. ApiException.message = "Http status error [400]" or similar
4. _sanitizeError returns this raw message directly
5. User sees raw technical error text in the task screen

**Worst case**: A non-DioException (StateError, FormatException, TypeError)
hits the `e.toString()` fallback, dumping implementation internals to the user.

### Impact
- Information disclosure: exposes internal error metadata to end users
- Inconsistency: breaks the centralized ErrorClassifier contract
- User trust: displays "Http status error [404]" instead of "Resource not found"

### Required Fix
Replace `_sanitizeError` body with:
```dart
String _sanitizeError(Object e) => ErrorClassifier.sanitizeMessage(e);
```
Delete the `_sanitizeError` function entirely and inline the call at all 7
catch sites, matching the pattern used by session_provider, chat_provider,
connection_provider, and profile_provider.

### Retest Method
1. `grep -rn "_sanitizeError" lib/features/tasks/` → 0 matches
2. Verify all 7 catch blocks use `ErrorClassifier.sanitizeMessage(e)`
3. Trigger task CRUD errors and verify user sees "Request failed" not raw messages

### Verdict
REJECT — Must fix before release. This is a direct regression from the
centralized ErrorClassifier pattern implemented in all other providers.

---

## Audit Finding

### Finding ID
AUD-RC6-002

### Severity
HIGH

### Affected Feature
FT-CHAT — Session history loading error display

### Evidence
`lib/features/chat/providers/chat_provider.dart:525`

```dart
} on ClientException catch (e) {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: ChatNotifier.loadHistory ClientException — ${e.message} ===');
    }
    state = state.copyWith(
      isLoadingHistory: false,
      errorMessage: e.message,  // ← RAW ClientException.message!
    );
  }
```

The `ClientException.message` is set from `_classifyError` (api_client.dart:177):
```dart
final message = error.message ?? 'Unknown error';
```
This is `DioException.message` — a raw technical string like
"Http status error [404]" or "Http status error [429]".

### Attack Path
1. Open a session with invalid/non-existent session ID
2. ChatNotifier.loadHistory() is called
3. Server returns 404 Not Found
4. The DioException goes through the onError interceptor → becomes ApiClient._classifyError
   → ClientException with message "Http status error [404]"
5. The onError interceptor creates a NEW DioException with .message = exception.message
   and .error = exception (the ApiException)
6. The catch block catches ClientException (which IS the .error on the DioException)
7. e.message = "Http status error [404]" flows directly to `state.errorMessage`

### Impact
- User sees "Http status error [404]" instead of "Resource not found"
- Inconsistent with all other error paths in the app
- Violates the centralized ErrorClassifier contract

### Required Fix
Change line 525 from:
```dart
errorMessage: e.message,
```
to:
```dart
errorMessage: ErrorClassifier.sanitizeMessage(e),
```

### Retest Method
1. Trigger a 404 on loadHistory (non-existent session ID)
2. Verify error message is user-friendly ("Resource not found"), not raw
3. Search for `.message` dereferences on caught exceptions in all providers

### Verdict
REJECT — Must fix. This is the ONLY remaining raw-exception-message leak in
chat_provider after all other paths were cleaned up.

---

---

## AV2: Certificate-Pinning Bypass (AUD-001)

### VERDICT: PASS — 0 CRITICAL, 0 HIGH

### All ApiClient Instances Verified:

| Provider | File | Line | certificatePinner | Status |
|----------|------|------|-------------------|--------|
| resolvedApiClientProvider | api_client_provider.dart | 55-58 | pinner (from certificatePinnerProvider) | PASS |
| chat_provider (ChatNotifier) | chat_provider.dart | 201-204 | pinner (from certificatePinnerProvider) | PASS |
| task_provider (TaskListNotifier init) | task_provider.dart | 142-145 | pinner (from certificatePinnerProvider) | PASS |
| task_provider (_getRepository) | task_provider.dart | 169-172 | pinner (from certificatePinnerProvider) | PASS |
| task_provider (taskDetailProvider) | task_provider.dart | 611-614 | pinner (from certificatePinnerProvider) | PASS |
| task_provider (modelListProvider) | task_provider.dart | 635-638 | pinner (from certificatePinnerProvider) | PASS |

All 6 ApiClient instantiations pass `certificatePinner: pinner`. Uniform coverage. PASS.

### validateCertificate Behavior:

**Debug/profile builds** (certificate_pinner.dart:73-98):
- Does NOT unconditionally return true without inspection
- Checks for existing pins and warns on mismatch (WARNING visible in logs)
- TOFU-pins on first connect (stores fingerprint for future comparison)
- Returns true (allowed) — correct for development

**Release builds** (certificate_pinner.dart:100-126):
- Enforces pinning: mismatch = REJECT (returns false)
- First connect: TOFU (accept + store)
- Subsequent connects: strict fingerprint comparison

**TOFU user confirmation** (certificate_pinner.dart:26-30):
- Acknowledged as deferred: "The user should be shown the certificate fingerprint
  and asked to confirm before trusting it"
- Tracked in GOAL_RC6_COMPREHENSIVE_REMEDIATION.md B.8
- Known MEDIUM finding, not blocking RC6

### Self-Signed Cert Scenario:
- First connect in release: TOFU accepts and pins → subsequent connections verify against pin
- First connect in debug/profile: silently accepts and pins → subsequent connections verify (warn on mismatch)
- If cert changes after pinning: release REJECTS, debug/profile WARNS but allows
- CORRECT behavior per spec

### Finding: AUD-B-8 (pre-existing, not new)
- TOFU without user-facing fingerprint confirmation
- Severity: MEDIUM (tracked under B.8, deferred to future release)
- Not a regression — exists by design

---

## AV3: Profile/Model Data Leakage

### VERDICT: PASS — 0 CRITICAL, 0 HIGH, 1 MEDIUM

### 3.1 API Key Leakage on Profile Switch

**Analysis**: When chat_provider detects a server switch (line 126-139):
```dart
ref.listen(connectionProvider, (prev, next) {
    final newServerId = next.activeServer?.id;
    if (newServerId != null && newServerId != _activeServerId) {
        _activeServerId = newServerId;
        _tearDown();           // Disposes old ApiClient + SSE stream
        state = ChatState();   // Resets ALL state
        initialize();          // Creates new ApiClient from NEW active server
    }
});
```

`initialize()` (line 174-182):
```dart
final authManager = AuthManager(secureStorage: SecureStorage());
final config = await authManager.getActiveServerConfig(); // Reads from secure storage
final apiKey = await authManager.getApiKey();              // key scoped by active server ID
```

The API key is scoped per serverId in secure storage. When the active server changes,
`getActiveServerId()` returns the new server ID, and `getApiKey()` retrieves that
server's key. The old key is NEVER held in chat_provider state (only in ApiClient
which is torn down). **PASS — no key leakage.**

### 3.2 Model Name Injection

`chat_provider.dart:284` — `selectModel(String modelId)` accepts any string.
However, the modelId is sent to the server which MUST validate it. The client
is a UX layer — the server is the source of truth. The modelId flows through to
API requests at lines 401 and 411. If the server accepts invalid model names,
that's a server-side issue. **LOW risk.**

### 3.3 Reasoning-Effort Injection ← FINDING

## Audit Finding

### Finding ID
AUD-RC6-003

### Severity
MEDIUM

### Affected Feature
FT-CHAT, FT-PROFILE — Reasoning effort parameter injection

### Evidence
`lib/features/chat/providers/chat_provider.dart:294-303`
```dart
void selectReasoningEffort(String? level) {
    state = state.copyWith(
      reasoningEffort: level,         // ← ANY string accepted
      clearReasoningEffort: level == null,
    );
}
```

The parameter flows to API at lines 402 and 414 without validation:
```dart
reasoningEffort: state.reasoningEffort,  // ← could be anything
```

Similarly in profile CRUD at `profile_provider.dart:128-144`:
```dart
reasoningEffort: reasoningEffort,  // ← raw String? from caller
```

The UI restricts values via PopupMenuButton (chat_screen.dart:147-173) to:
'default', 'none', 'low', 'medium', 'high'

But a programmatic caller through the provider can inject arbitrary values.
The HermesProfile Isar model (hermes_profile.dart:44) stores it as `String?`
with no enum constraint.

### Attack Path
1. Call `ref.read(chatProvider.notifier).selectReasoningEffort('malicious_payload')`
2. The value flows to the API as `{"reasoning_effort": "malicious_payload"}`
3. Server may reject, silently ignore, or (worst case) interpret it

### Impact
- Payload injection into API requests
- Potential for oversized values causing request size issues
- Inconsistent with UI-enforced value set

### Required Fix
Add an enum or string validation in selectReasoningEffort:
```dart
static const _validLevels = {null, 'none', 'low', 'medium', 'high'};
void selectReasoningEffort(String? level) {
    if (level != null && !_validLevels.contains(level)) return;
    ...
}
```

### Retest Method
1. Try `selectReasoningEffort('invalid_value')` — should be no-op
2. Verify only valid values reach the API payload
3. Same validation in profile_provider.dart create/update paths

### Verdict
Needs Fix — MEDIUM. Client-side validation gap. Server should also validate.

### 3.4 Isar Injection

Isar uses typed query builders, not raw SQL/strings. The HermesProfile model
uses `@collection` with typed fields. Queries are type-safe Dart calls.
**PASS — no injection vectors.**

---

## AV4: FLAG_SECURE Removal Verification

### VERDICT: PASS — CONFIRMED FULLY REMOVED

### Evidence:
```
$ grep -rn "FLAG_SECURE" android/
android/app/src/main/kotlin/com/jahfali/hermex_android/MainActivity.kt
    9:  // FLAG_SECURE intentionally removed per owner directive.
```

**Zero active instances.** The only match is a comment documenting the removal.

### MainActivity.kt (entire file):
```kotlin
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // FLAG_SECURE intentionally removed per owner directive.
        // GOAL_RC6_COMPREHENSIVE_REMEDIATION.md G.25
    }
}
```

No `onResume` override. No `onWindowFocusChanged` override. No `FLAG_SECURE`
in `AndroidManifest.xml` or any other Android native file.

**CONFIRMED: All 3 instances removed. ADR-011 (permanent removal) enforced.**

---

## AV5: Input Validation

### VERDICT: PASS (with AUD-RC6-003 noted above)

### 5.1 Model Name Injection
- `selectModel(String modelId)` — no client-side validation
- Server is source of truth for model existence
- Risk: LOW — server should reject invalid model names

### 5.2 Profile Name / Server URL Injection
- Profile name: stored in Isar as String, no format validation
- Server URL: validated via `_validateUrl` (server_repository.dart:255-296)
  - Rejects empty URL
  - Requires http:// or https:// scheme
  - **Blocks userinfo injection** (line 268: `uri.userInfo.isNotEmpty`)
  - HTTP only allowed on RFC 1918 private networks
- Risk: LOW for name (Isar type-safe), LOW for URL (validated)

### 5.3 Reasoning Effort Value Injection
- Covered under AUD-RC6-003 above

---

# BLACK SWAN PROBES

## Black Swan Probe 1: Concurrent Profile Switch + Chat Send

### Feature
FT-CHAT, FT-PROFILE

### Scenario
1. User initiates a chat message send (SSE stream opens)
2. Mid-stream, user switches to a different profile/server
3. connectionProvider fires → chat_provider listener detects server switch
4. `_tearDown()` is called → cancels active SSE stream + disposes ApiClient
5. `state = ChatState()` resets all messages to empty
6. `initialize()` creates new ApiClient for new server

### Failure Risk
- The in-flight SSE stream is cancelled mid-response
- The agent message in the chat list may be left in `isStreaming: true` state
- Since `state = ChatState()` resets everything, the streaming message is lost
  (no data corruption risk, just UX jarring)

### Verdict
MEDIUM — UX issue. The old streaming message disappears. User loses partial
response. Mitigated by the fact that profile switching is an explicit user
action that implies "I'm done with this conversation."

---

## Black Swan Probe 2: Over-the-limit ReasoningEffort String

### Feature
FT-CHAT, FT-PROFILE

### Scenario
1. User creates a profile with `reasoningEffort` set to a 1MB string
2. The value is persisted to Isar (no length limit on `String?` field)
3. On next chat request, the 1MB string is serialized into the API JSON payload
4. The API request body exceeds reasonable size

### Failure Risk
- Isar stores and retrieves the oversized string without issue
- The API request becomes enormous (~1MB JSON body for a chat message)
- Dio serializes it, server may reject with 413 or timeout
- No client-side truncation or validation

### Verdict
MEDIUM — Client should enforce max length (e.g., 100 chars for reasoningEffort).
Same applies to defaultModelId and profile name.

---

## Black Swan Probe 3: TOFU Pin Poisoning via Shared Network

### Feature
FT-CONNECTION, FT-SECURITY

### Scenario
1. User connects to their Hermes server from a coffee shop WiFi
2. An attacker runs a MITM proxy with a self-signed cert
3. First connection: TOFU pins the attacker's cert fingerprint
4. User goes home, connects to the REAL server — mismatch → REJECTED
5. User is permanently locked out (pinned to attacker's cert)

### Failure Risk
- TOFU on first use is vulnerable to first-use MITM
- No certificate transparency or pinning list validation
- Once a malicious pin is stored, user must manually clear pins

### Verdict
LOW — This is inherent to TOFU design and documented as B.8 limitation.
Mitigated by: attacker must be present on first-ever connection AND run MITM.
User can clear pins via CertificatePinner.clearAll().

---

# SUMMARY OF ALL FINDINGS

| ID | Severity | Feature | Summary | Verdict |
|----|----------|---------|---------|---------|
| AUD-RC6-001 | CRITICAL | FT-TASKS | _sanitizeError bypasses ErrorClassifier, leaks raw messages in 7 paths | REJECT |
| AUD-RC6-002 | HIGH | FT-CHAT | ClientException.message leaked directly to UI at loadHistory:525 | REJECT |
| AUD-RC6-003 | MEDIUM | FT-CHAT/PROFILE | No input validation on reasoningEffort — arbitrary string injection | NEEDS FIX |
| AUD-B-8 | MEDIUM | FT-SECURITY | TOFU without user confirmation (pre-existing, not RC6 regression) | TRACKED |
| BS-1 | MEDIUM | FT-CHAT | Concurrent profile switch + chat send loses in-flight response | UX NOTE |
| BS-2 | MEDIUM | FT-CHAT/PROFILE | No length limit on reasoningEffort/defaultModelId strings | NEEDS FIX |
| BS-3 | LOW | FT-SECURITY | First-use TOFU MITM vulnerability (inherent to TOFU design) | DOCUMENTED |

---

# ATTACK VECTOR PASS/FAIL SUMMARY

| Vector | Status | Critical | High | Medium | Low |
|--------|--------|----------|------|--------|-----|
| AV1: Raw-Error Leakage | PARTIAL PASS | 1 | 1 | 0 | 0 |
| AV2: Certificate Pinning | PASS | 0 | 0 | 1 (B.8) | 0 |
| AV3: Profile/Model Leakage | PASS | 0 | 0 | 1 | 1 |
| AV4: FLAG_SECURE Removal | PASS | 0 | 0 | 0 | 0 |
| AV5: Input Validation | PASS | 0 | 0 | 1 | 2 |

---

# RELEASE GATE DECISION

**GATE: CONDITIONAL PASS**

RC6 can proceed to Phase 5 (APK build + release) ONLY AFTER:
1. AUD-RC6-001 (CRITICAL): task_provider _sanitizeError → ErrorClassifier.sanitizeMessage
2. AUD-RC6-002 (HIGH): chat_provider:525 ClientException.message → ErrorClassifier.sanitizeMessage

AUD-RC6-003 (MEDIUM, reasoningEffort validation) is recommended but non-blocking.
BS-2 (string length limits) is recommended hardening, non-blocking.
