# 01 — PRD: Hermex Android

## Product Overview

A Flutter mobile application that serves as a native control plane for self-hosted Hermes Agent instances. Users connect to their own Hermes Agent API Server and manage all agent operations from their phone.

## Core Value Proposition

**Your server. Your phone. No middleman.**  
Unlike the iOS Hermex app (which requires `hermes-webui` middleware), Hermex Android connects directly to Hermes Agent's built-in API Server — zero additional dependencies beyond a running Hermes Agent.

## Target Users

| Persona | Needs |
|---------|-------|
| **Power User (Abdulrahman)** | Full agent control from phone: chat, manage cron, browse files, check skills |
| **Developer** | Debug sessions, run commands, check memory/insights |
| **Casual User** | Chat with agent, check scheduled task results |

## Feature List (MVP)

### F-001: Server Connection
- Server URL + API key input
- Connection health check (GET /health)
- Persistent server config (encrypted local storage)
- Multiple server profiles support

### F-002: Chat
- Real-time SSE streaming chat
- Model selection (from server's available models)
- Message history (load from session)
- Markdown rendering (code blocks, tables, images)
- File/image attachment support
- Stop/interrupt running agent turn
- Tool call visibility (hermes.tool.progress events)

### F-003: Sessions
- Session list with search
- Session details (messages, metadata)
- Create/rename/delete sessions
- Fork/branch sessions
- Archive/pin sessions
- Session status indicators

### F-004: Tasks (Cron Jobs)
- List scheduled jobs
- Job details (schedule, last run, status)
- Create/edit/delete jobs
- Pause/resume jobs
- Trigger immediate run
- View job output

### F-005: Skills Browser
- List installed skills with descriptions
- Search/filter skills
- View skill content
- Toggle skills on/off

### F-006: Workspace Browser
- Directory listing
- File content preview
- Navigate folder structure
- File metadata display

### F-007: Memory & Insights
- Read-only memory view
- Usage insights (tokens, sessions, active time)
- Stats dashboard

### F-008: Settings
- Server management (add/remove/switch)
- Theme (dark mode default)
- Model preference
- Profile switching
- About / version info

## Non-MVP Features (Future)

- Voice input (transcribe API)
- TTS output (phone speaks agent response)
- Widget (home screen quick chat)
- Notifications (cron job results)
- Offline session cache
- Multi-account support

## Exit Criteria (MVP)

- [ ] Connect to Hermes Agent API Server on port 8642
- [ ] Real-time chat with SSE streaming
- [ ] Browse and manage sessions
- [ ] Manage cron jobs
- [ ] Browse skills and workspace
- [ ] View memory and insights
- [ ] All features work on Android 8.0+
- [ ] Zero-trust audit passed
- [ ] QA acceptance tests passed
