/goal

## Objective
Comprehensive remediation of Hermex Android: fix the broken error-handling/security
architecture, add first-class Hermes Profile support (per-profile model + reasoning-effort
control), fix model selection (currently dead code), fix mid-session profile-switch bug,
remove FLAG_SECURE, and complete the app-wide light-theme/visual-design pass.

## Context
- Project: Hermex Android — /Users/abdurrahmanjahfali/Projects/hermex_android
- Spec pack: app-spec/
- What exists: Flutter + Riverpod + GoRouter + Dio + Isar client for the Hermes Agent API
  Server. Chat (SSE streaming), Sessions, Tasks/cron, Skills, Workspace, Memory, Settings,
  multi-server connection management, Material 3 dark/light theme.
- What doesn't work: see Specific Defects below — spans error-handling architecture,
  certificate pinning, profile/model/reasoning-effort features, and residual theme bugs.

## Specific Defects

### A. Error-handling & security architecture (CRITICAL)
1. lib/core/api/api_client.dart:41 — `validateStatus` accepts all codes <500; Dio never
   throws on 4xx responses (401/403/404 etc.).
2. lib/core/api/api_client.dart:59-68 — `onError` interceptor computes a classified
   exception but calls `handler.next(error)` with the ORIGINAL DioException, discarding
   the classification. `AuthException`/`ClientException` (defined lines 169-198) are
   effectively dead code.
3. lib/features/chat/providers/chat_provider.dart:427-436 — `AuthException`/
   `ConnectionException` catch branches in `loadHistory()` are unreachable because of #2.
4. Raw exception text still reaches the UI (confirmed unfixed despite a prior audit
   claiming PASS — see Process Integrity note below):
   - lib/features/sessions/providers/session_provider.dart — 6 catch blocks (create/
     rename/delete/update/fork session, ~lines 195,247,298,331,367,413) interpolate raw
     `$e` into user-facing `errorMessage`.
   - lib/features/chat/providers/chat_provider.dart:562-565 — `'Error: ${error.toString()}'`
     shown directly in a chat bubble.
   - lib/features/chat/providers/stream_provider.dart:84 — `message: error.toString()`.
   - task_provider.dart already does this correctly via a `_sanitizeError()` helper —
     use that as the reference pattern to apply everywhere else.
5. lib/features/tasks/data/task_repository.dart:255 — a second, divergent
   `_classifyError` duplicate of api_client.dart:169; error classification logic is
   duplicated and inconsistent across features. Consolidate into one shared utility.
6. lib/core/api/api_client.dart:233-280 (`_SizeLimitInterceptor`) — only checks
   `data is String` / `data is List`, never `data is Map` — the dominant response shape
   for this API. The OOM-protection guard doesn't actually cover most responses.

### B. Certificate / transport security (CRITICAL/MAJOR)
7. lib/core/security/certificate_pinner.dart:63-71 — `validateCertificate` unconditionally
   returns `true` outside `kReleaseMode` — TLS validation is fully disabled in debug/profile
   builds, not just relaxed.
8. certificate_pinner.dart:73-99 — TOFU-pins the first-seen certificate with no user-facing
   confirmation/fingerprint display.
9. lib/features/chat/providers/chat_provider.dart:154 and
   lib/features/tasks/providers/task_provider.dart:137,157,592 — construct `ApiClient(...)`
   directly WITHOUT `certificatePinner`, bypassing pinning entirely for Chat and Tasks
   traffic (Sessions/Insights/Memory/Workspace/Skills correctly go through
   `resolvedApiClientProvider` which wires it — use that as the reference pattern).
10. lib/core/providers/api_client_provider.dart:29-36 — `apiClientProvider` is a dead
    stub that always returns null; either wire it or remove it.

### C. Profile / server-switching (MAJOR — core to the product's purpose)
11. lib/models/server_config.dart:10-29 — `ServerConfig` only has id/name/url/isDefault/
    lastConnected. There is no first-class "Hermes Profile" entity carrying per-profile
    default model and reasoning-effort settings.
12. lib/features/chat/providers/chat_provider.dart — `ChatNotifier.initialize()`
    (lines 116-127) reads the active server once via `AuthManager.getActiveServerConfig()`
    and guards with `if (state.isInitialized && _repository != null) return;`. It does not
    reactively watch `connectionProvider`. Switching servers/profiles while the chat screen
    is alive leaves chat silently talking to the OLD server/API key until the user manually
    taps "New Chat". Sessions correctly react to server switches via
    `resolvedApiClientProvider` — mirror that pattern for chat.
13. lib/features/sessions/data/session_repository.dart:151 — `CachedSession.serverId` is
    set to `_apiClient.dio.options.baseUrl` instead of the actual `ServerConfig.id` — a
    fragile foreign key if a server's URL ever changes.

### D. Model selection (CRITICAL — literally broken today)
14. lib/features/chat/presentation/model_selector.dart — dead code, never instantiated
    anywhere in the app.
15. lib/features/chat/providers/chat_provider.dart:165-166 — code comment admits the model
    selector UI was removed per a past directive with no replacement; chat always falls
    back to the hardcoded string `'hermes-default'`.
16. lib/models/model_info.dart:8-19 — `ModelInfo` only carries id/object/created/ownedBy —
    no capability or reasoning-effort metadata fields.
17. lib/features/settings/presentation/settings_screen.dart:217-245 — "Default Model" is a
    free-text field persisted via `defaultModelProvider`
    (lib/features/settings/providers/settings_provider.dart:172-173) but is NEVER read by
    chat_provider.dart — a fully orphaned setting.
18. lib/features/tasks/presentation/task_form_screen.dart:41,313-320 — task model field is
    free-text (`_modelNameController`), not bound to the server's real `/v1/models` list.

### E. Reasoning-effort / "thinking" control (CRITICAL — entirely absent)
19. Full-repo grep (`grep -rniE "thinking|reasoning|effort" lib/`) returns ZERO matches —
    no UI, no model field, no API plumbing exists anywhere for this.
20. lib/core/api/endpoints.dart — confirm what the live Hermes server actually accepts for
    reasoning-effort/thinking-budget parameters (check server-side `/v1/chat/completions`
    and `/v1/responses` payload schema) before adding the client-side field — this needs a
    Backend/DB Architect contract-verification step, not a guess.

### F. Design / visual polish (MAJOR)
21. lib/features/chat/presentation/message_bubble.dart:141 — agent bubble background is
    still hardcoded to `HermesColors.agentBubble` (#161B22, a dark color), unconditional on
    theme brightness — flagged as the single most user-visible issue in UX_SIGNOFF_RC5.md
    and still unfixed.
22. Residual hardcoded `HermesColors.textDisabled` (non-theme-adaptive) in:
    settings_screen.dart (~136,227,643), insights_screen.dart (~183,188,208),
    session_list_screen.dart (~210,360,376,609,623,646), chat_screen.dart (~242,256).
23. General visual-polish pass needed beyond contrast bugs — spacing, typography hierarchy,
    empty-state consistency, iconography — per the owner's "looks ugly/generic" complaint.
    UI/UX Designer should treat this as a full design-system consistency audit, not just a
    bug list.

### G. Other feature gaps (MINOR/MAJOR)
24. lib/features/sessions/data/session_repository.dart:30-57 and
    session_list_screen.dart:69-102 — session search is client-side only on the fully
    fetched list; no server-side query/pagination/cursor support.
25. android/app/src/main/kotlin/.../MainActivity.kt — `FLAG_SECURE` (blocks screenshots/
    screen recording) is set in three places (onCreate/onResume/onWindowFocusChanged).
    **Owner has explicitly confirmed: remove all three, fully.** This was previously
    reinstated by the swarm against an earlier removal request — do not re-add it.

### H. Process integrity (flag for Documentation Steward + Lead Architect — governance, not code)
26. The RC5 Gate2 security audit (docs/audit/RC5_GATE2_SECURITY_AUDIT.md) REJECTED the
    release over AUD-RC5-001/002. A same-day "Gate4 rescan" declared PASS by only
    re-verifying older already-passing items — it never mentions or retests AUD-RC5-001/002.
    Item A.4 above proves those two findings are still live in the code today. Log a
    decision-log entry reconciling this (tie to existing LL-029/038/040 patterns already in
    app-spec/00_lessons_learned.md) so QA/Auditor gates cannot be marked PASS without
    re-testing the SPECIFIC findings that caused the prior REJECT.

## Phases & Worker Assignments
- Phase 0: Product Steward — confirm scope against PRD; log ADRs for (a) Profile as a
  first-class entity with per-profile default model + reasoning-effort, (b) FLAG_SECURE
  removal — both owner-approved, record so they aren't silently reversed again.
- Phase 1 (parallel):
  - UI/UX Designer — screen specs for: Profile switcher/management UI, model + reasoning-
    effort selector (in chat and in profile settings), full light-theme fix (message
    bubble + remaining textDisabled instances), and a general visual-consistency pass
    across all screens.
  - Backend/DB Architect — design the `HermesProfile` Isar entity (id, name, serverId FK,
    defaultModelId, reasoningEffort, isActive) migrating from flat `ServerConfig`; verify
    against the live Hermes server what reasoning-effort/thinking parameters `/v1/chat/
    completions` and `/v1/responses` actually accept (item E.20); design the single
    shared error-classification contract to replace the broken interceptor + duplicated
    `_classifyError`.
- Phase 2: State Engineer — implement all items A-G above, in dependency order (error-
  handling/cert-pinning fixes first since later features depend on reliable error
  surfacing; then Profile entity + reactive chat re-init; then model/reasoning-effort UI;
  then theme fixes; then FLAG_SECURE removal; then session search/pagination).
- Phase 3: QA Tester — widget/integration tests for all changes. Must explicitly re-run
  a Truth Check against AUD-RC5-001/002 specifically (item H.26) with grep/test evidence,
  not a re-stamp of unrelated items.
- Phase 4: Zero-Trust Auditor — hostile re-audit targeting: raw-error leakage (the
  previously-falsely-cleared findings), certificate-pinning bypass, and the new Profile/
  model/reasoning-effort features for credential or data leakage.
- Phase 5: DevOps Release Engineer — rebuild APK (confirm FLAG_SECURE removal doesn't
  break other release assumptions), publish release.
- Guardian: SCSI Hunter — continuous scan throughout.
- Documentation Steward: update CHANGELOG.md, app-spec/12_decision_log.md, and add a
  lessons-learned entry documenting the Gate4-rescan-that-didn't-recheck-critical-findings
  incident (item H.26), so gate reports must re-verify the exact findings that caused a
  prior REJECT before claiming PASS.

## Workers to Skip
None — this EPIC touches every domain (architecture, security, data model, UI, QA, audit,
release, docs).

## Exit Criteria (Machine-Checkable)
- [ ] flutter analyze: 0 errors
- [ ] flutter test: all pass, count ≥ 484 (current baseline)
- [ ] grep -rn "HermesColors\.\(textPrimary\|textSecondary\|surface\|agentBubble\)" across
      settings_screen.dart, insights_screen.dart, session_list_screen.dart,
      message_bubble.dart → 0 non-brand matches
- [ ] grep -rniE "thinking|reasoning|effort" lib/ → matches present AND wired end-to-end
      (verified by a live chat request that actually varies reasoning effort)
- [ ] Model switching verified end-to-end against a live Hermes server — selected model
      actually used in the chat request, not just displayed in UI
- [ ] Profile switch mid-chat-session verified to cleanly reset chat state and point at
      the new server (no stale-server bug)
- [ ] grep -rn "FLAG_SECURE" android/ → 0 matches
- [ ] AUD-RC5-001 and AUD-RC5-002 re-audited with concrete evidence they're fixed (not a
      re-stamp of other items)
- [ ] Certificate pinning applied uniformly across ALL ApiClient instances (chat, tasks,
      sessions, insights, memory, workspace, skills)
- [ ] Git pushed to remote
- [ ] APK built and smoke-tested on a real Android device
- [ ] GitHub Release published with 'latest' tag
- [ ] SCSI Guardian: APPROVED

## File Paths
- Spec pack: /Users/abdurrahmanjahfali/Projects/hermex_android/app-spec/
- Source: /Users/abdurrahmanjahfali/Projects/hermex_android/lib/
- Tests: /Users/abdurrahmanjahfali/Projects/hermex_android/test/
- Android native: /Users/abdurrahmanjahfali/Projects/hermex_android/android/
