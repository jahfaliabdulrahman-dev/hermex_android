# KANBAN BOARD — 6 Critical Bugs Fix
# hermex_android | 2026-07-08
# Board created by: flutter-lead-architect

## Dependency Graph

```
🏛️ t_62425b71: ARCHITECTURE REVIEW (Triple Chinese MoA)
│  └── Approves auth key fix strategy + endpoint feature-gating
│
├── 🔴 t_3c912589: BUG-1 — Model Selector (AUTH KEY FIX)
│   ├── 🔴 t_e4fa70fd: BUG-5-Skills (depends on auth fix)
│   ├── 🟠 t_9df6c8ca: BUG-2 — Sessions (depends on auth fix)
│   └── 🔒 t_601753a4: ZERO-TRUST AUDIT (depends on auth fix)
│
├── 🔴 t_68176d76: BUG-5-Memory (endpoint feature-gate)
├── 🔴 t_5b328773: BUG-5-Insights (endpoint feature-gate)
├── 🟠 t_5e7aae5a: BUG-3 — Workspace (endpoint feature-gate)
├── 🟡 t_491b6092: BUG-4 — Profile Name (fix hardcoded string)
├── 🟡 t_3785973f: BUG-6 — Dialog Text (fix theme)
│
├── 🧪 t_46067b88: QA VALIDATION (depends on all 6 fix tasks)
├── 📚 t_2a84f9bd: DOCUMENTATION (update lessons + spec)
└── 🛡️ t_c1399d5f: SCSI GUARDIAN (continuous, goal-mode 999 turns)
```

## Board Status

| Task ID | Title | Assignee | Status | Dependencies |
|---------|-------|----------|--------|--------------|
| `t_62425b71` | 🏛️ ARCHITECTURE REVIEW: Auth key + endpoint gating | flutter-lead-architect | **ready** | — |
| `t_3c912589` | 🔴 BUG-1: Fix Model Selector — auth key validation | flutter-state-engineer | **ready** | — |
| `t_e4fa70fd` | 🔴 BUG-5-Skills: Fix Skills page (auth) | flutter-state-engineer | **todo** | t_3c912589 |
| `t_9df6c8ca` | 🟠 BUG-2: Sessions page fix | flutter-state-engineer | **todo** | t_3c912589 |
| `t_601753a4` | 🔒 ZERO-TRUST AUDIT: API key handling | flutter-zero-trust-auditor | **todo** | t_3c912589 |
| `t_68176d76` | 🔴 BUG-5-Memory: Feature-gate /v1/memory | flutter-backend-db-architect | **ready** | — |
| `t_5b328773` | 🔴 BUG-5-Insights: Feature-gate /v1/insights | flutter-backend-db-architect | **ready** | — |
| `t_5e7aae5a` | 🟠 BUG-3: Workspace feature-gate | flutter-product-steward | **ready** | — |
| `t_491b6092` | 🟡 BUG-4: Profile name → dynamic | flutter-state-engineer | **ready** | — |
| `t_3785973f` | 🟡 BUG-6: Dialog text visibility | flutter-ui-ux-designer | **ready** | — |
| `t_46067b88` | 🧪 QA VALIDATION: All 6 bugs | flutter-qa-tester | **todo** | All 6 fix tasks |
| `t_2a84f9bd` | 📚 DOCUMENTATION: Lessons + spec | flutter-documentation-steward | **ready** | — |
| `t_c1399d5f` | 🛡️ SCSI GUARDIAN | flutter-curiosity-hunter | **ready** | — |

## Implementation Order

### Wave 1: Auth Fix (unblocks multiple bugs)
1. **t_62425b71**: Architecture Review → approve auth strategy
2. **t_3c912589**: Fix API key in connection flow → HEAL_CHECK first
3. → Unblocks: t_e4fa70fd (Skills), t_9df6c8ca (Sessions), t_601753a4 (Security Audit)

### Wave 2: Endpoint Feature-Gating (parallel)
4. **t_68176d76**: BUG-5-Memory → feature-gate /v1/memory (404)
5. **t_5b328773**: BUG-5-Insights → feature-gate /v1/insights (404)
6. **t_5e7aae5a**: BUG-3-Workspace → feature-gate /v1/workspace (404)

### Wave 3: UX Fixes (parallel)
7. **t_491b6092**: BUG-4 → dynamic profile name
8. **t_3785973f**: BUG-6 → fix dialog text colors

### Wave 4: Validation
9. **t_46067b88**: QA → device test + analyze + tests
10. **t_2a84f9bd**: Documentation → LL-031 through LL-036

### Continuous
11. **t_c1399d5f**: SCSI Guardian → perpetual audit loop
