# 00 — Project Context: Hermex Android

## Project Identity

| Field | Value |
|-------|-------|
| **Project Name** | Hermex Android |
| **Code Name** | `hermex_android` |
| **Type** | Flutter mobile application (iOS + Android) |
| **Owner** | Eng. Abdulrahman Jahfali |
| **Start Date** | 2026-07-04 |
| **License** | MIT |

## What This Is

A Flutter-based mobile client for **Hermes Agent API Server** (port 8642).  
Native control plane for a self-hosted Hermes Agent — chat, sessions, cron jobs, skills, workspace browsing, memory, and insights.

**Not** a port of the iOS Hermex app. This connects **directly** to Hermes Agent's built-in OpenAI-compatible API Server — no `hermes-webui` middleware needed.

## Architecture Decision

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Framework** | Flutter | Single codebase for iOS + Android. Eng. Abdulrahman is Flutter expert. |
| **Backend API** | Hermes Agent API Server (port 8642) | Built-in, OpenAI-compatible, Nous-supported. No middleware. |
| **State Management** | Riverpod | Proven in CarSah. Type-safe, testable, scalable. |
| **Networking** | Dio + custom SSE parser | Dio for REST, raw HTTP for SSE streaming |
| **Local Storage** | Isar (if needed for offline cache) | Proven in CarSah |
| **Navigation** | GoRouter | Declarative routing with deep linking |
| **Design System** | Material 3, dark theme | Hermes brand: navy #001F5E, cyan #32C2FF |

## Server Dependency

```yaml
# Required in ~/.hermes/.env:
API_SERVER_ENABLED: true
API_SERVER_PORT: 8642
API_SERVER_KEY: <bearer token>
```

The app connects to `http://<server-ip>:8642/v1` with Bearer auth.  
SSE streaming for real-time chat. Standard OpenAI-compatible endpoints.

## Target Platforms

| Platform | Min Version | Status |
|----------|------------|--------|
| Android | API 26 (Android 8.0) | Primary target |
| iOS | iOS 16+ | Secondary (expands beyond Hermex) |

## Development Swarm

9 Hermes profiles via Kanban dispatcher:
- `flutter-lead-architect` — Orchestration
- `flutter-product-steward` — PRD & scope
- `flutter-ui-ux-designer` — Screens & design tokens
- `flutter-backend-db-architect` — Local persistence schema
- `flutter-state-engineer` — Implementation
- `flutter-qa-tester` — Testing
- `flutter-zero-trust-auditor` — Security audit
- `flutter-devops-release-engineer` — CI/CD & release
- `flutter-documentation-steward` — Spec pack maintenance

Model: Triple Chinese MoA (DeepSeek-v4-pro + Qwen3.7-max + GLM-5.2 via OpenRouter)
