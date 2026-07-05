# AGENTS.md — Hermex Android

## Project: Hermex Android
Flutter mobile client for Hermes Agent API Server.

## Spec Pack
All specifications in `app-spec/` (22 files).
Read ALL spec files before writing any code.

## Architecture
- Flutter + Riverpod + GoRouter + Dio
- Clean Architecture (core → features → models)
- Material 3 dark theme (navy #001F5E, cyan #32C2FF)
- SSE streaming via raw HttpClient

## Server Dependency
Hermes Agent API Server on port 8642.
Must be running with API_SERVER_ENABLED=true.

## Swarm
9 Flutter profiles orchestrated by flutter-lead-architect via Kanban.
Triple Chinese MoA: deepseek-v4-pro + qwen3.7-max + glm-5.2.

## Golden Rule
Contract Before Code. Spec Pack is the source of truth.
Never write code without corresponding spec.
