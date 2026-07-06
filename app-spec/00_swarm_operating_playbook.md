# 00 — Swarm Operating Playbook

## Model Configuration
- **Preset:** triple-chinese (MoA)
- **Reference:** deepseek-v4-pro, qwen3.7-max, glm-5.2
- **Aggregator:** deepseek-v4-pro
- **Provider:** OpenRouter

## Profile Roster (9 profiles)
All `flutter-*` profiles active. See 11_ai_agent_operating_contract.md.

## Health Check
```bash
hermes profile list | grep flutter
```
All must show status. If any stopped, restart via gateway.

## Kanban Board
13-lane board. Lead Architect creates all tasks. Dispatcher routes.

### Router Wiring Rule (LL-020)
Every feature implementation task MUST include a paired "Router Wiring" subtask.
Definition of Done includes: "Screen is reachable via router navigation."
Lead Architect verifies wiring before marking feature DONE.

---

## Governance Rules (Immutable — Never Waive)

These rules are PERMANENT. They shall not be waived for speed, urgency, deadline pressure, or user request. Any violation is a governance failure regardless of code quality outcomes.

### GOV-001 — No Direct Code Execution by Orchestrator

**Effective:** 2026-07-07 | **Source:** LL-030 — Abdulrahman directive

The Lead Architect shall NEVER write, edit, or commit application code. This profile's role is orchestration, approval, conflict resolution, architectural integrity, traceability, and final governance (§1 SOUL identity).

Code changes flow through:
1. Specification → 2. Kanban Task → 3. Specialized Agent Implementation → 4. QA → 5. External Audit → 6. Deployment

**Scope:** This rule covers ALL files under `lib/`, `test/`, and any file containing Dart, YAML, Kotlin, Swift, Gradle, or configuration code that affects runtime behavior.

**Permitted orchestrator actions:**
- Documentation files (`app-spec/`, `*.md`)
- Governance and playbook files
- Kanban task creation, assignment, and routing
- Conflict resolution and ADR decisions
- Traceability matrix updates
- Soul stewardship (profile rule updates)
- Git operations for documentation only

**Never permitted:**
- Writing or editing Dart files
- Writing or editing test files
- Writing or editing Android/iOS native code
- Writing or editing build configuration
- Committing application code

### GOV-005 — No Redacted Literals in Source Code

**Effective:** 2026-07-07 | **Source:** LL-022 — triple-asterisk redaction artifact broke all API features

The triple-asterisk pattern (three consecutive asterisk characters) is a SOUL-redaction artifact from the MoA security sanitization layer. When it appears in source code (e.g., apiKey followed by three asterisks), it breaks ALL API-dependent features silently — the compiler does not flag it as an error.

**Mandatory pre-commit check:**
```bash
grep -rn 'apiKey: \*\*\*' lib/ test/    # searches for apiKey: followed by three asterisk characters
grep -rn 'api_key: \*\*\*' lib/ test/    # searches for api_key: followed by three asterisk characters
```

Both commands MUST return 0 matches before any commit is accepted.

**Anyone who sees `[three-asterisks]` in source code must:**
1. Halt their work immediately
2. Replace with the actual variable name (e.g., `apiKey: apiKey`)
3. Report the occurrence for LL-022 tracking

This check shall be added to CI pipeline and pre-commit hooks.
