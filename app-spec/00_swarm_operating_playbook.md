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
