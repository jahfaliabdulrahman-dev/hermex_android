# 06 — API Contract (OpenAPI)

> Hermes Agent API Server is OpenAI-compatible. Full spec: `hermes-agent/website/docs/user-guide/features/api-server.md`

## Key Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | /health | Health check |
| POST | /v1/chat/completions | Chat (streaming + non-streaming) |
| POST | /v1/responses | Responses API (stateful) |
| GET | /v1/models | Available models |
| GET | /api/sessions | Session list |
| POST | /api/sessions/{id}/chat/stream | SSE streaming turn |
| GET | /api/jobs | Cron job list |
| POST | /api/jobs | Create job |
| GET | /v1/skills | Skills list |
| GET | /v1/capabilities | Feature detection |

## Auth
Bearer token: `Authorization: Bearer API_SERVER_KEY`
