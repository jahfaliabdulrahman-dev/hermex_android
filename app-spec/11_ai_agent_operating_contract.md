# 11 — AI Agent Operating Contract: Hermex Android

## Purpose

This contract defines how the 9 Flutter profiles interact during the development of Hermex Android via Kanban swarm orchestration.

## Profile Assignments

| Profile | Lane | Responsibilities |
|---------|------|-----------------|
| `flutter-lead-architect` | ARCHITECTURE_REVIEW | Approve architecture, resolve conflicts, traceability |
| `flutter-product-steward` | PRODUCT_REVIEW | PRD enforcement, scope boundaries, Gherkin scenarios |
| `flutter-ui-ux-designer` | UX_DESIGN | Material 3 screens, JSPP brand, RTL support, component states |
| `flutter-backend-db-architect` | BACKEND_DESIGN | Isar schema, local persistence, data integrity |
| `flutter-state-engineer` | FLUTTER_IMPLEMENTATION | Feature implementation, Riverpod providers, widget code |
| `flutter-qa-tester` | QA_VALIDATION | Widget tests, integration tests, acceptance criteria |
| `flutter-zero-trust-auditor` | HOSTILE_AUDIT | Security audit, data leakage, credential handling |
| `flutter-devops-release-engineer` | DEVOPS_RELEASE_REVIEW | CI/CD, build config, signing, release gates |
| `flutter-documentation-steward` | DOCUMENTATION_GATE | Spec pack maintenance, lessons learned, cross-references |

## Global Rules (from FLUTTER_GLOBAL_CONTRACT.md)

1. **Zero Assumptions** — report ambiguity, never guess
2. **Contract Before Code** — spec must exist before implementation
3. **Backend as Source of Truth** — Hermes Agent API Server is authoritative
4. **Anti-Ghost Protocol** — soft delete by default
5. **No Magic Strings** — all constants centralized in `core/constants/`
6. **No Unapproved Packages** — escalate new dependencies to Lead Architect
7. **Traceability Required** — Feature → Spec → Test → Audit
8. **Validation Payload Required** — every handoff includes proof
9. **No Procedural Reduction** — all UI states, edge cases, error handling mandatory
10. **No Client-Side Entitlement** — server validates all auth

## Communication Contract

### During Implementation (Phase 2)
- Profiles work in **isolated sessions** via Kanban dispatcher
- They read specs, produce output, hand off to next profile
- **NO clarifying questions during implementation** — specs are the contract
- If spec is ambiguous: escalate to Lead Architect via `kanban_block(reason="spec ambiguity: ...")`

### Handoff Format
```
**Handoff from [Profile] to [Next Profile]**
- Task: [task_id]
- Summary: [what was done]
- Files Changed: [list]
- Tests: [N passed, M failed]
- Decisions Made: [list with rationale]
- Open Concerns: [if any]
- Next Step: [which profile, which task]
```

### Escalation Triggers
- Spec ambiguity that blocks implementation
- Package dependency addition needed
- Schema change not in spec
- Security concern discovered
- Test failure that's not a code bug

## MoA Configuration

All profiles use the `triple-chinese` MoA preset:
- Reference: deepseek-v4-pro + qwen3.7-max + glm-5.2
- Aggregator: deepseek-v4-pro
- Provider: OpenRouter

## Success Criteria

- [ ] All MVP features implemented (F-001 to F-008)
- [ ] 100% test pass rate
- [ ] Zero-trust audit clean
- [ ] APK builds successfully
- [ ] Connected to live Hermes Agent API Server
- [ ] Chat with SSE streaming functional
- [ ] All 9 profiles contributed to deliverables
