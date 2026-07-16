# 19 — Traceability Matrix

> Last Updated: 2026-07-16
> Maps every feature (F-001 to F-008) across all spec files, implementation, and tests.
> **Router Wired column populated by T2-R (t_ecd75ad7):** ChatScreen, WorkspaceScreen, SkillsScreen wired to GoRouter in app_router.dart. See LL-017.

## Traceability Legend

| Column | Source |
|--------|--------|
| Feature ID | 01_prd.md |
| Feature Name | 01_prd.md |
| Product Req | 01_prd.md |
| UX Spec | 04_ui_design_system.md |
| User Flows | 03_user_flows_navigation.md |
| API Endpoints | 06_api_contract.md |
| Data Models | 05_data_model_erd.md |
| Business Rules | 02_monetization_entitlements.md, 17_data_architecture_acid_constraints.md |
| Security Rules | 08_security_privacy.md, 18_zero_trust_red_team_audit.md |
| Gherkin Scenarios | 09_testing_acceptance.md |
| Feature Folder | lib/features/ |
| Implementation | lib/ (files) |
| **Router Wired** | app_router.dart import + route entry (LL-017) |
| Test Files | test/ |
| Audit Status | 18_zero_trust_red_team_audit.md |

---

## F-001: Server Connection

| Dimension | Reference | Status |
|-----------|-----------|--------|
| Product Req | 01_prd.md §F-001 | ✅ |
| UX Spec | 04_ui_design_system.md §Connection Screen | ✅ |
| User Flows | 03_user_flows_navigation.md §1 (First Connection) | ✅ |
| API Endpoints | GET /health (06_api_contract.md) | ✅ |
| Data Models | ServerConfig (05_data_model_erd.md) | ✅ |
| Business Rules | Server configs encrypted (17 §Data Integrity #1, 02 §Free) | ✅ |
| Security Rules | API key encrypted at rest (08 §Credential Storage), HTTP local-only (08 §Network Security) | ✅ |
| Gherkin Scenarios | AC-F001-01 through AC-F001-14 (14 scenarios) | ✅ |
| Feature Folder | lib/features/connection/ | ✅ |
| Implementation | server_repository.dart, connection_provider.dart, connection_screen.dart, server_list_screen.dart | ✅ |
| Router Wired | app_router.dart import + route entry (LL-017, T2-R) | ✅ |
| Test Files | server_repository_test.dart, connection_provider_test.dart, connection_screen_test.dart, server_list_screen_test.dart | ✅ |
| Audit Status | Vectors 1, 2, 3, 5 relevant — partial coverage in 08 | ⚠️ Partial |

## F-002: Chat (SSE Streaming)

| Dimension | Reference | Status |
|-----------|-----------|--------|
| Product Req | 01_prd.md §F-002 | ✅ |
| UX Spec | 04_ui_design_system.md §Chat Screen, §Chat Bubbles | ✅ |
| User Flows | 03_user_flows_navigation.md §2 | ✅ |
| API Endpoints | POST /v1/chat/completions, POST /api/sessions/{id}/chat/stream (06) | ✅ |
| Data Models | ChatMessage, StreamEvent, ModelInfo (05) | ✅ |
| Business Rules | No data stored locally beyond session cache (17) | ✅ |
| Security Rules | SSE over HTTPS/HTTP-local (08), SSE stream poisoning (18 #7) — not mitigated in 08 | ⚠️ Partial |
| Gherkin Scenarios | AC-F002-01 through AC-F002-13 (13 scenarios) | ✅ |
| Feature Folder | lib/features/chat/ | ✅ |
| Implementation | chat_screen.dart, chat_input.dart, message_bubble.dart, model_selector.dart, chat_provider.dart, stream_provider.dart, chat_repository.dart | ✅ |
| Router Wired | app_router.dart import + route entry (LL-017, T2-R) | ✅ |
| Test Files | chat_screen_test.dart, chat_provider_test.dart, stream_provider_test.dart | ✅ |
| Audit Status | SSE poisoning (18 #7) not explicitly mitigated | ⚠️ Gap |

## F-003: Sessions

| Dimension | Reference | Status |
|-----------|-----------|--------|
| Product Req | 01_prd.md §F-003 | ✅ |
| UX Spec | 04_ui_design_system.md §Sessions Screen | ✅ |
| User Flows | 03_user_flows_navigation.md §3 | ✅ |
| API Endpoints | GET /api/sessions, GET /api/sessions/{id}/messages (06) | ✅ |
| Data Models | SessionSummary (05), CachedSession (05) | ✅ |
| Business Rules | Session cache TTL 7 days (17 §Data Integrity #3), Soft-delete (17 §Anti-Ghost) | ✅ |
| Security Rules | Cached sessions non-sensitive — unencrypted Isar (17) | ✅ |
| Gherkin Scenarios | AC-F003-01 through AC-F003-14 (14 scenarios) | ✅ |
| Feature Folder | lib/features/sessions/ | ✅ |
| Implementation | session_list_screen.dart, session_detail_screen.dart, session_provider.dart, session_repository.dart | ✅ |
| Router Wired | app_router.dart import + route entry (LL-017, T2-R) | ✅ |
| Test Files | session_list_screen_test.dart, session_provider_test.dart, session_repository_test.dart | ✅ |
| Audit Status | All relevant vectors covered | ✅ |

## F-004: Tasks (Cron Jobs)

| Dimension | Reference | Status |
|-----------|-----------|--------|
| Product Req | 01_prd.md §F-004 | ✅ |
| UX Spec | 04_ui_design_system.md §Tasks Screen | ✅ |
| User Flows | 03_user_flows_navigation.md §4 | ✅ |
| API Endpoints | GET /api/jobs, POST /api/jobs (06) | ✅ |
| Data Models | CronJob (05) | ✅ |
| Business Rules | Server-validated (02), No client-side entitlement (11 §10) | ✅ |
| Security Rules | Bearer token auth for all job mutations (06, 08) | ✅ |
| Gherkin Scenarios | AC-F004-01 through AC-F004-14 (14 scenarios) | ✅ |
| Feature Folder | lib/features/tasks/ | ✅ |
| Implementation | task_list_screen.dart, task_detail_screen.dart, task_form_screen.dart, task_provider.dart, task_repository.dart | ✅ |
| Router Wired | app_router.dart import + route entry (LL-017, T2-R) | ✅ |
| Test Files | task_list_screen_test.dart, task_detail_screen_test.dart, task_provider_test.dart, task_repository_test.dart | ✅ |
| Audit Status | Input injection (18 #6) — CronJob uses freezed with safe defaults | ✅ |

## F-005: Skills Browser

| Dimension | Reference | Status |
|-----------|-----------|--------|
| Product Req | 01_prd.md §F-005 | ✅ |
| UX Spec | 04_ui_design_system.md §Skills Browser (Settings sub-screen) | ✅ |
| User Flows | 03_user_flows_navigation.md §Settings sub-screens | ✅ |
| API Endpoints | GET /v1/skills (06) | ✅ |
| Data Models | Skill (05) | ✅ |
| Business Rules | Read-only toggle (no server mutation endpoint) — optimistic UI only | ⚠️ Limitation |
| Security Rules | Read-only — no data mutation risk | ✅ |
| Gherkin Scenarios | AC-F005-01 through AC-F005-09 (9 scenarios) | ✅ |
| Feature Folder | lib/features/skills/ | ✅ |
| Implementation | skills_screen.dart, skills_provider.dart, skills_repository.dart | ✅ |
| Router Wired | app_router.dart import + route entry (LL-017, T2-R) | ✅ |
| Test Files | skills_screen_test.dart, skills_provider_test.dart, skills_repository_test.dart | ✅ |
| Audit Status | Low risk — read-only feature | ✅ |

## F-006: Workspace Browser

| Dimension | Reference | Status |
|-----------|-----------|--------|
| Product Req | 01_prd.md §F-006 | ✅ |
| UX Spec | 04_ui_design_system.md §Workspace Screen | ✅ |
| User Flows | 03_user_flows_navigation.md §Bottom Nav: Workspace | ✅ |
| API Endpoints | GET /v1/workspace (implemented, not in 06 spec) | ⚠️ Spec gap |
| Data Models | WorkspaceEntry (lib/models/, not in 05 spec) | ⚠️ Spec gap |
| Business Rules | Binary files preview blocked, large dirs paginated | ✅ |
| Security Rules | Path traversal — server validates paths | ✅ |
| Gherkin Scenarios | AC-F006-01 through AC-F006-11 (11 scenarios) | ✅ |
| Feature Folder | lib/features/workspace/ | ✅ |
| Implementation | workspace_screen.dart, workspace_provider.dart, workspace_repository.dart | ✅ |
| Router Wired | app_router.dart import + route entry (LL-017, T2-R) | ✅ |
| Test Files | workspace_screen_test.dart, workspace_provider_test.dart, workspace_repository_test.dart | ✅ |
| Audit Status | Server-side path validation (risk: server implementation) | ⚠️ Server-dependent |

## F-007: Memory & Insights

| Dimension | Reference | Status |
|-----------|-----------|--------|
| Product Req | 01_prd.md §F-007 | ✅ |
| UX Spec | 04_ui_design_system.md §Memory/Insights (Settings sub-screens) | ✅ |
| User Flows | 03_user_flows_navigation.md §Settings sub-screens | ✅ |
| API Endpoints | GET /v1/memory, GET /v1/insights (implemented, not in 06 spec) | ⚠️ Spec gap |
| Data Models | MemoryEntry, InsightsData (lib/models/, not in 05 spec) | ⚠️ Spec gap |
| Business Rules | Read-only — "manage memory on server" indicator shown | ✅ |
| Security Rules | Memory may contain sensitive data — displayed read-only | ✅ |
| Gherkin Scenarios | AC-F007-01 through AC-F007-07 (7 scenarios) | ✅ |
| Feature Folder | lib/features/memory/, lib/features/insights/ | ✅ |
| Implementation | memory_screen.dart, memory_provider.dart, insights_screen.dart, insights_provider.dart | ✅ |
| Router Wired | app_router.dart import + route entry (LL-017, T2-R) | ✅ |
| Test Files | memory_screen_test.dart, memory_entry_test.dart, insights_data_test.dart | ✅ |
| Audit Status | Read-only — low risk | ✅ |

## F-008: Settings

| Dimension | Reference | Status |
|-----------|-----------|--------|
| Product Req | 01_prd.md §F-008 | ✅ |
| UX Spec | 04_ui_design_system.md §Settings Screen | ✅ |
| User Flows | 03_user_flows_navigation.md §Settings tab, sub-screens | ✅ |
| API Endpoints | GET /v1/models (for model preference), health checks for server mgmt (06) | ✅ |
| Data Models | UserPreference (05), ServerConfig (05) | ✅ |
| Business Rules | Theme preference persisted (SharedPreferences), Model preference local (17) | ✅ |
| Security Rules | Server config encrypted (08), Profile switching — Hermes Agent profiles (not server switching) | ✅ |
| Gherkin Scenarios | AC-F008-01 through AC-F008-11 (11 scenarios) | ✅ |
| Feature Folder | lib/features/settings/ | ✅ |
| Implementation | settings_screen.dart, settings_provider.dart | ✅ |
| Router Wired | app_router.dart import + route entry (LL-017, T2-R) | ✅ |
| Test Files | settings_screen_test.dart, settings_provider_test.dart | ✅ |
| Audit Status | Clipboard exposure (18 #9), Background snapshot (18 #10) — not mitigated | ⚠️ Gap |

---

## Coverage Summary

| Feature | Specs | Implementation | Tests | Router Wired | Audit |
|---------|-------|---------------|-------|-------------|-------|
| F-001 | ✅ | ✅ | ✅ | ✅ | ⚠️ Partial |
| F-002 | ✅ | ✅ | ✅ | ✅ | ⚠️ SSE poisoning |
| F-003 | ✅ | ✅ | ✅ | ✅ | ✅ |
| F-004 | ✅ | ✅ | ✅ | ✅ | ✅ |
| F-005 | ✅ | ✅ | ✅ | ✅ | ✅ |
| F-006 | ⚠️ API gap | ✅ | ✅ | ✅ | ⚠️ Server-dependent |
| F-007 | ⚠️ API gap | ✅ | ✅ | ✅ | ✅ |
| F-008 | ✅ | ✅ | ✅ | ✅ | ⚠️ 2 vectors |

## Spec Gaps Requiring Lead Architect Attention

1. **06_api_contract.md** — Missing `/v1/memory`, `/v1/insights`, `/v1/workspace` endpoints
2. **05_data_model_erd.md** — Missing WorkspaceEntry, MemoryEntry, InsightsData models
3. **08_security_privacy.md** — Missing mitigations for vectors 4-10 from 18_zero_trust_red_team_audit.md
4. **Duplicate ApiEndpoints** — `lib/core/api/` vs `lib/core/constants/`
