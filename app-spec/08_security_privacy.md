# 08 — Security & Privacy

**Version:** 1.1
**Last Updated:** 2026-07-06
**Cross-Reference:** [18 — Zero-Trust Red Team Audit](./18_zero_trust_red_team_audit.md)

## Credential Storage
- API keys → flutter_secure_storage (OS-level encryption)
- Server URLs → SharedPreferences (non-sensitive)

## Network Security
- HTTPS enforced for remote connections
- HTTP allowed only for local network (192.168.x.x, 10.x.x.x)
- Certificate pinning for production builds

## Data Privacy
- No analytics, no tracking, no third-party relay
- All data stays between app and user's own server
- No telemetry

## Attack Surface — Vectors 1–3 (Credential & Network Layer)

| Vector | Threat | Mitigation |
|--------|--------|------------|
| VEC-001 Credential Leakage | API key exposed in logs, screenshots, process memory | flutter_secure_storage (OS-level Keychain/EncryptedSharedPreferences); no plaintext caching; debugPrint stripped in release builds |
| VEC-002 MITM | HTTP intercepted on shared network | HTTPS enforced for remote; HTTP allowed only for local network (RFC 1918); network_security_config.xml blocking cleartext remote traffic |
| VEC-003 Server Impersonation | Wrong server URL accepted, traffic routed to attacker | First-connect confirmation dialog; host validation against RFC 3986; no implicit trust of user-entered URLs |

---

## Red Team Attack Vectors — Vectors 4–10 (Runtime & Platform Layer)

### VEC-004: Token Replay

- **Audit Finding:** AUD-004 (PASS)
- **Threat:** Captured bearer token reused after session expiration or device compromise.
- **MVP Applicability:** Full — API key is the sole authentication mechanism.
- **Current Mitigation:**
  - API key stored exclusively in `flutter_secure_storage` (OS-level encrypted at rest: iOS Keychain, Android EncryptedSharedPreferences).
  - API key read asynchronously per-request; never held in plaintext beyond call scope.
  - No token caching in SharedPreferences or Isar.
  - On server profile soft-delete, associated API key is purged from secure storage.
- **Limitation (known):** On rooted/jailbroken devices, `flutter_secure_storage` can be bypassed. This is a platform limitation — not a code flaw. Root detection is a V2 consideration.
- **V2 Guardrails:**
  - Root/jailbreak detection via `flutter_jailbreak_detection` or SafetyNet attestation.
  - Optional biometric-bound key storage (Android Keystore with `setUserAuthenticationRequired`).
  - Server-side token rotation with short-lived tokens (requires Hermes Agent API v2 token endpoint).

### VEC-005: Local Storage Extraction

- **Audit Finding:** AUD-005 (PASS with note)
- **Threat:** Attacker with rooted device extracts unencrypted local database.
- **MVP Applicability:** Partial — Isar stores session cache (non-sensitive per spec).
- **Current Mitigation:**
  - Isar DB opened without encryption — by design. Stores only session metadata, message cache, and UI state.
  - All sensitive data (API keys, server configs) routed to `flutter_secure_storage`, not Isar.
  - `android:allowBackup="false"` in AndroidManifest — prevents Android backup extraction of app data.
  - User preferences in SharedPreferences contain only non-sensitive values (theme, sort order, display preferences).
- **Limitation (known):** If user types sensitive data into session titles, those titles are stored unencrypted in Isar.
- **V2 Guardrails:**
  - Isar encryption via `Isar.open(..., encryptionKey: key)` with key derived from biometric or secure storage.
  - Session title content-sensitivity scanner (detect API keys, passwords, tokens in user-entered text).
  - Periodic Isar integrity verification.

### VEC-006: Input Injection (Oversized / Poisoned Payload)

- **Audit Finding:** AUD-006 (WARN — Medium)
- **Remedial Task:** t_4e9be9c9
- **Threat:** Malicious or compromised server sends oversized JSON payloads in SSE events or API responses, causing OOM crash.
- **MVP Applicability:** Full — all API and SSE endpoints process server-controlled data.
- **Current Mitigation:**
  - SSE parser catches `FormatException` on malformed JSON; stream continues without crash.
  - UTF-8 decode failures caught by outer try/catch in SSE client.
  - Dio HTTP client has configurable timeouts per request.
- **Gap (pre-V2 fix needed):**
  - No size limit on SSE event data — `jsonDecode(data)` can allocate unbounded memory.
  - No content-length validation on Dio responses.
  - No truncation of TextDelta content in StreamManager before UI rendering.
- **Required Fix (t_4e9be9c9):**
  1. Max SSE event size cap (1 MB) in `_parseEvent()` — reject/truncate oversized events.
  2. Max response body size in Dio interceptor (configurable, default 10 MB).
  3. TextDelta content length cap in StreamManager (prevents UI-level OOM from giant text chunks).
- **V2 Guardrails:**
  - JSON depth limit (max nesting 20 levels).
  - Array length cap (max 10,000 elements).
  - Differential fuzzing of all API endpoints against Hermes Agent server.
  - Crash-loop detection: if app crashes 3 times within 60 seconds, disable SSE auto-reconnect.

### VEC-007: SSE Stream Poisoning

- **Audit Finding:** AUD-007 (PASS)
- **Threat:** Malformed SSE data injected into stream crashes the app, leaks memory, or injects malicious content.
- **MVP Applicability:** Full — chat is SSE-streamed from server.
- **Current Mitigation:**
  - Missing `"data:"` prefix: ignored — parser checks `line.startsWith('data: ')` before processing.
  - Invalid JSON in data field: `_parseEvent()` catches `FormatException`, logs, returns null; stream continues.
  - Truncation mid-event: partial data block never emitted (requires empty line to flush) — safe by SSE protocol design.
  - Binary data injection: UTF-8 decoder throws, caught by outer try/catch; event discarded.
  - `"[DONE]"` signal: handled explicitly; stream terminates gracefully.
  - Unknown event format: logged and skipped; no crash.
  - No regex-based parsing — line-oriented SSE parsing avoids catastrophic backtracking.
- **V2 Guardrails:**
  - SSE event schema validation (JSON Schema) before processing.
  - Rate limiting on SSE events per second (throttle UI updates).
  - Memory watermark monitoring during streaming — abort if heap exceeds threshold.

### VEC-008: Deep Link Hijack

- **Audit Finding:** AUD-008 (PASS)
- **Threat:** Custom URI scheme (e.g., `hermex://...`) exploited by malicious app to inject commands, open unintended routes, or steal credentials.
- **MVP Applicability:** None — MVP registers no custom URI schemes.
- **Current Mitigation:**
  - No `android:scheme="hermex"` or equivalent intent filter in AndroidManifest.xml.
  - GoRouter uses standard path-based routing only (`/connection`, `/chat`, `/sessions`, etc.).
  - No deep link handler registered — `app_router.dart` has zero `DeepLink` or `onGenerateRoute` overrides for external URIs.
  - Activity is `android:exported="true"` only for MAIN/LAUNCHER intent — standard for Flutter and not exploitable for data injection.
- **V2 Guardrails:**
  - If deep links are added in V2 (e.g., `hermex://chat?session=...`), implement verified app links (Android App Links / iOS Universal Links) with assetlinks.json verification.
  - Whitelist-only route table for deep link destinations.
  - No credential or API key data passed via deep link query parameters.

### VEC-009: Clipboard Exposure

- **Audit Finding:** AUD-009 (PASS)
- **Threat:** Sensitive data (API keys, tokens, server URLs) inadvertently copied to system clipboard and accessible to other apps.
- **MVP Applicability:** Full — app has text input fields and copy functionality.
- **Current Mitigation:**
  - Zero instances of API key being copied to clipboard anywhere in `lib/`.
  - Copy functionality limited to user-initiated actions: chat message text (MessageBubble long-press) and version string.
  - API key input field uses `obscureText: true` — prevents shoulder-surfing and accidental selection.
  - No automatic copy-on-connect or copy-on-generate for any credential.
- **V2 Guardrails:**
  - Clipboard content cleared on app background (Android: `ClipboardManager.clearPrimaryClip()`).
  - `Clipboard.setData` wrapper that auto-clears after configurable timeout (30 seconds).
  - Sensitive content detection on clipboard write — block if pattern matches API key regex.

### VEC-010: Background Snapshot (App Switcher)

- **Audit Finding:** AUD-010 (WARN → FIXED)
- **Threat:** App switcher screenshot reveals sensitive data (chat messages, server URLs, model names) when user switches apps.
- **MVP Applicability:** Full — all screens are visible in app switcher by default.
- **Current Mitigation:**
  - **FIXED:** `MainActivity.kt` sets `FLAG_SECURE` on the activity window in `onCreate`. This blocks:
    - App switcher snapshots (Android shows blank/obscured thumbnail).
    - User-initiated screenshots (system blocks capture).
    - Screen recording (content hidden in recording).
  - API key field uses `obscureText: true` by default (defense-in-depth even without FLAG_SECURE).
  - `android:allowBackup="false"` prevents backup-based data extraction.
- **V2 Guardrails:**
  - Per-screen FLAG_SECURE: allow screenshots on non-sensitive screens (home, about) while blocking on chat, settings, and connection screens.
  - `AppLifecycleState` listener to blur/obscure sensitive data when `AppLifecycleState.inactive`.
  - Custom app switcher overlay (Android `onPictureInPictureModeChanged` or blank surface).

---

## Remedial Task Summary

| Task ID | Vector | Severity | Title | Status |
|---------|--------|----------|-------|--------|
| t_a0f8a7db | VEC-002 | Critical | MITM Protection — network_security_config.xml, HTTP enforcement, cert pinning | Open |
| t_d72f9181 | VEC-003 | Medium | Server Impersonation — host validation, first-connect confirmation | Open |
| t_4e9be9c9 | VEC-006 | Medium | Input Injection — size/depth limits on incoming data | Open |
| t_209cbecc | VEC-010 | Low | Background Snapshot — FLAG_SECURE for app switcher | ✅ Fixed |

## Cross-References

- [18 — Zero-Trust Red Team Audit](./18_zero_trust_red_team_audit.md) — Full audit report with evidence, attack paths, and code references for all 10 vectors.
- [05 — Data Model & ERD](./05_data_model_erd.md) — Local storage strategy and schema.
- [06 — API Contract](./06_api_contract.md) — SSE and REST endpoint definitions.
