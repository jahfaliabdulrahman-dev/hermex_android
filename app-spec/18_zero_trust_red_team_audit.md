# 18 — Zero-Trust Red Team Audit

## Mandatory Attack Vectors

| # | Vector | Test |
|---|--------|------|
| 1 | Credential leakage | API key in logs, screenshots, process memory |
| 2 | MITM | HTTP (non-HTTPS) connections intercepted |
| 3 | Server impersonation | Wrong server URL accepted |
| 4 | Token replay | Captured bearer token reused |
| 5 | Local storage extraction | Rooted device reads secure storage |
| 6 | Input injection | Malicious server responses crash app |
| 7 | SSE stream poisoning | Malformed SSE data handled safely |
| 8 | Deep link hijack | Custom URI schemes exploited |
| 9 | Clipboard exposure | API key copied to clipboard |
| 10 | Background snapshot | App switcher shows sensitive data |

## Audit Status

- [x] All vectors tested
- [x] Findings documented
- [ ] Critical issues resolved
- [ ] Re-audit after implementation

---

## Audit Report — 2026-07-05

### Summary

| Metric | Count |
|--------|-------|
| Total vectors | 10 |
| PASS | 6 |
| WARN | 3 |
| FAIL | 1 |
| Remedial tasks | 4 |

---

### AUD-001: MITM Protection Missing

**Severity:** Critical — FAIL
**Feature:** FT-001 (Server Connection)
**Remedial:** t_a0f8a7db

**Evidence:**
1. `android/app/src/main/AndroidManifest.xml:10` references `android:networkSecurityConfig="@xml/network_security_config"` but `res/xml/network_security_config.xml` does NOT exist in the source tree.
2. `lib/features/connection/data/server_repository.dart:232`: URL validation accepts any `http://` URL. The `isLocalNetwork()` helper (line 283-296) exists but is used only for a cosmetic UI hint — NOT for blocking non-local HTTP.
3. Spec `08_security_privacy.md` mandates: "HTTPS enforced for remote connections," "HTTP allowed only for local network," "Certificate pinning for production builds." Zero of these implemented.

**Attack Path:** Attacker on same Wi-Fi network performs ARP spoofing → intercepts HTTP traffic → reads API key and all chat content in cleartext.

**Impact:** Full credential and data compromise in MITM scenario.

**Required Fix:**
1. Create `android/app/src/main/res/xml/network_security_config.xml` blocking cleartext for remote.
2. Enforce HTTP-only-on-local-network in `_validateUrl()`.
3. Add certificate pinning for production builds.

---

### AUD-002: Debug Log Interceptor Active in Release Builds

**Severity:** Low — WARN
**Feature:** FT-001 (Server Connection)

**Evidence:**
1. `lib/core/api/api_client.dart:147-168`: `_DebugLogInterceptor` has NO `kDebugMode` guard. It is always active regardless of build mode.
2. While API keys are NOT logged (only URI and status code), request paths, server URLs, and error details are logged to `debugPrint`. In Flutter, `debugPrint` is stripped in release mode by the engine — so this is low-risk, but the interceptor runs needlessly in release.

**Attack Path:** If a custom logger intercepts `debugPrint` in a release-like build, server URLs and request paths are exposed.

**Impact:** Minor information disclosure (request timing, paths, server URLs).

**Required Fix:** Wrap interceptor in `if (kDebugMode)` guard.

---

### AUD-003: Server Impersonation

**Severity:** Medium — WARN
**Feature:** FT-001 (Server Connection)
**Remedial:** t_d72f9181

**Evidence:**
1. `lib/features/connection/data/server_repository.dart:221-237`: `_validateUrl()` only checks for `http://` or `https://` prefix + URI parsability. No host allowlist/blocklist.
2. An attacker who socially engineers the user to enter `http://evil-server.com:8642` would successfully establish a connection to the attacker's server.
3. Spec lists mitigation as "user verification of server URL" — this is a social defense, not technical.

**Attack Path:** Phishing email/social engineering → user enters attacker's server URL → all subsequent API calls go to attacker's server.

**Impact:** Full data exfiltration to attacker-controlled server.

**Required Fix:**
1. Block non-RFC-1918 hosts when using http:// scheme.
2. Add first-connect confirmation dialog showing full URL.
3. Validate URL against RFC 3986 to prevent host injection.

---

### AUD-004: Token Replay

**Severity:** — PASS
**Feature:** FT-001 (Server Connection)

**Evidence:**
1. API key stored in `flutter_secure_storage` (OS-level Keychain/EncryptedSharedPreferences) — `lib/core/storage/secure_storage.dart:14,102-103`.
2. `lib/core/auth/auth_manager.dart:93-97`: API key read asynchronously, never held in plaintext beyond call scope.
3. No token caching in SharedPreferences (non-encrypted storage).
4. On soft-delete, associated API key is deleted — `lib/features/connection/data/server_repository.dart:80-82`.

**Note:** On rooted devices, `flutter_secure_storage` can be bypassed. This is a platform limitation, not a code flaw.

---

### AUD-005: Local Storage Extraction

**Severity:** — PASS (with note)
**Feature:** FT-001 (Server Connection)

**Evidence:**
1. Isar DB opened without encryption — `lib/data/datasources/local/isar_provider.dart:34-39`. This matches the spec: Isar stores only non-sensitive session cache (spec `05_data_model_erd.md` §Local Storage Strategy).
2. Server configs and API keys use `flutter_secure_storage` — OS-encrypted at rest. `lib/core/storage/secure_storage.dart:112`.
3. User preferences use `SharedPreferences` (non-sensitive, per spec).

**Note:** If users type sensitive data into session titles, those titles are stored unencrypted in Isar. Consider adding a content-sensitivity warning or Isar encryption.

---

### AUD-006: Input Injection — No Size/Depth Limits

**Severity:** Medium — WARN
**Feature:** FT-002 (Chat), FT-007 (SSE)
**Remedial:** t_4e9be9c9

**Evidence:**
1. `lib/core/api/sse_client.dart:135`: `jsonDecode(data)` — no size limit or depth guard on incoming SSE event data.
2. `lib/core/api/api_client.dart:62,74`: Dio response parsing with no content-length validation.
3. `lib/features/chat/providers/stream_provider.dart:65`: Stream events forwarded to UI with no truncation.

**Attack Path:** Malicious server sends 100MB JSON in an SSE event → `jsonDecode` allocates 100MB → OOM crash → app killed.

**Impact:** Denial of service via OOM. Potential crash-loop if malformed data is cached.

**Required Fix:**
1. Max SSE event size (1MB) in `_parseEvent()`.
2. Max response body size in Dio interceptor.
3. TextDelta content length cap in StreamManager.

---

### AUD-007: SSE Stream Poisoning

**Severity:** — PASS
**Feature:** FT-002 (Chat)

**Evidence:**
1. Missing "data:" prefix: ignored — `sse_client.dart:88` checks `line.startsWith('data: ')`.
2. Invalid JSON in data field: `_parseEvent()` catches `FormatException`, logs, returns null — `sse_client.dart:175-178`. Stream continues without crash.
3. Truncation mid-event: partial data block never emitted (requires empty line to flush) — safe.
4. Binary data injection: UTF-8 decoder throws, caught by outer try/catch — `sse_client.dart:109-111`.
5. "[DONE]" signal: handled — `sse_client.dart:91-94`.
6. Unknown event format: logged and skipped — `sse_client.dart:172-174`.

---

### AUD-008: Deep Link Hijack

**Severity:** — PASS
**Feature:** FT-000 (Router)

**Evidence:**
1. No custom URI scheme defined in `AndroidManifest.xml` — no `android:scheme="hermex"` intent filter.
2. GoRouter routes use standard paths only: `/connection`, `/chat`, `/sessions`, `/tasks`, `/skills`, etc. No deep link handler registered — `lib/core/router/app_router.dart:29-128`.
3. Activity has `android:exported="true"` but only for MAIN/LAUNCHER — standard for Flutter apps.

---

### AUD-009: Clipboard Exposure

**Severity:** — PASS
**Feature:** FT-002 (Chat), FT-008 (Settings)

**Evidence:**
1. No code copies API key to clipboard anywhere in `lib/`.
2. `lib/features/chat/presentation/message_bubble.dart:40`: copies `message.content` (chat message text). Acceptable — this is user-initiated content sharing, not credential leakage.
3. `lib/features/settings/presentation/settings_screen.dart:402`: copies version string `"0.1.0"` — harmless.
4. API key input field uses `obscureText: true` — `connection_screen.dart:295`.

---

### AUD-010: Background Snapshot

**Severity:** Low — WARN
**Feature:** FT-000 (App Shell)
**Remedial:** t_209cbecc

**Evidence:**
1. Zero instances of `FLAG_SECURE`, `secure_window`, `WindowManager`, or `AppLifecycleState` handling in `lib/` — confirmed via grep.
2. Android app switcher captures a screenshot of the current activity. This will show: server URLs (not obscured), chat messages (potentially sensitive), model names, settings values.
3. API key field is obscured by default BUT the toggle visibility button could expose it in a snapshot if toggled on during app switch.
4. `android:allowBackup="false"` is set (good) — prevents backup extraction of app data.

**Attack Path:** Attacker with physical device access → app switcher → screenshot of sensitive chat content or server URL.

**Impact:** Day-to-day content leakage (chat messages, server IPs). Low severity because API key is obscured by default.

**Required Fix:** Set `FLAG_SECURE` on the activity window to prevent app switcher snapshots entirely.

**Status:** ✅ FIXED — `MainActivity.kt` now sets `FLAG_SECURE` in `onCreate`. App switcher snapshots, screenshots, and screen recording are blocked OS-level on all screens.

---

## Remedial Tasks Created

| Task ID | Vector | Severity | Title |
|---------|--------|----------|-------|
| t_a0f8a7db | AUD-001 | Critical | MITM Protection — network_security_config.xml, HTTP enforcement, cert pinning |
| t_d72f9181 | AUD-003 | Medium | Server Impersonation — host validation, first-connect confirmation |
| t_4e9be9c9 | AUD-006 | Medium | Input Injection — size/depth limits on incoming data |
| t_209cbecc | AUD-010 | Low | Background Snapshot — FLAG_SECURE for app switcher |
