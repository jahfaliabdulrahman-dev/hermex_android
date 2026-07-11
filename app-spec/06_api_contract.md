# 06 — API Contract (OpenAPI)

> Hermes Agent API Server is OpenAI-compatible. Full spec: `hermes-agent/website/docs/user-guide/features/api-server.md`
>
> **Last Updated:** 2026-07-11 (added /api/jobs pagination doc)

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
| GET | /v1/memory | Agent memory entries (read-only) |
| GET | /v1/insights | Usage statistics / insights |
| GET | /v1/workspace | Root directory listing |
| GET | /v1/workspace/{path} | Subdirectory listing or file content |

## Auth

All endpoints (except `/health`): `Authorization: Bearer <hermes-api-key>`

---

## GET /v1/memory

Returns all agent memory entries.

### Request

```
GET /v1/memory
Authorization: Bearer <token>
```

No query parameters. No request body.

### Response

**200 OK** — Returns a JSON object with a `memories` array (also accepts `data` or bare array forms):

```json
{
  "memories": [
    {
      "id": "abc123",
      "title": "User prefers dark mode",
      "description": "The user has explicitly requested dark mode in all apps.",
      "created_at": "2026-06-15T08:30:00Z",
      "updated_at": "2026-07-01T14:22:00Z"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | string | yes | Unique memory identifier (falls back to `key` field if present) |
| title | string | yes | Short title / key for this memory (falls back to `key` or `name`) |
| description | string | no | Full description or value of the memory entry |
| created_at | ISO 8601 | no | Server-side creation timestamp |
| updated_at | ISO 8601 | no | Server-side last-updated timestamp |

**Alternative response formats accepted by the Flutter client:**

| Server shape | Parsed as |
|-------------|-----------|
| `[ {...}, ... ]` | Direct list |
| `{ "memories": [...] }` | Extracts list from `memories` key |
| `{ "data": [...] }` | Extracts list from `data` key |
| `{ "results": [...] }` | Extracts list from `results` key |

**Error responses:**

| Status | Condition |
|--------|-----------|
| 401 | Missing or invalid bearer token |
| 500 | Server error — client shows error banner with retry |

### Client Behavior (Hermex)

- `memoryListProvider` (FutureProvider) fetches on screen mount
- Returns empty list when no server connected
- Pull-to-refresh supported
- Search/filter on title and description (client-side)

---

## GET /v1/insights

Returns agent usage statistics and insights.

### Request

```
GET /v1/insights
Authorization: Bearer <token>
```

No query parameters. No request body.

### Response

**200 OK** — Returns a JSON object with usage statistics:

```json
{
  "total_sessions": 42,
  "total_messages": 1250,
  "total_tokens": 450000,
  "active_time_minutes": 320,
  "last_synced": "2026-07-06T12:00:00Z",
  "cron_jobs_run": 18,
  "skills_count": 12
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| total_sessions | integer | yes | Total number of sessions (defaults to 0) |
| total_messages | integer | yes | Total messages across all sessions (defaults to 0) |
| total_tokens | integer | yes | Total tokens consumed (input + output, defaults to 0) |
| active_time_minutes | integer | yes | Approximate active time in minutes (defaults to 0) |
| last_synced | ISO 8601 | no | Server-side last sync timestamp |
| cron_jobs_run | integer | yes | Number of cron jobs executed (defaults to 0) |
| skills_count | integer | yes | Number of installed skills (defaults to 0) |

**Alternative response formats accepted by the Flutter client:**

| Server shape | Parsed as |
|-------------|-----------|
| `{ "total_sessions": ..., ... }` | Direct object |
| `{ "insights": { ... } }` | Extracts from `insights` key |
| `{ "data": { ... } }` | Extracts from `data` key |

**Error responses:**

| Status | Condition |
|--------|-----------|
| 401 | Missing or invalid bearer token |
| 500 | Server error — client shows error banner with retry |

### Client Behavior (Hermex)

- `insightsProvider` (FutureProvider) fetches on screen mount
- Returns default-zero `InsightsData` when no server connected
- All-zero data treated as "empty state" with guidance message
- Formatted display: tokens (k/M suffix), active time (Xh Ym)
- Pull-to-refresh supported

---

## GET /v1/workspace

Returns a directory listing of the root workspace.

### Request

```
GET /v1/workspace
Authorization: Bearer <token>
```

| Query Param | Type | Required | Default | Description |
|-------------|------|----------|---------|-------------|
| path | string | no | (root) | Directory path to list |

No request body.

### Response

**200 OK** — Returns a JSON object with a `data` array of entries:

```json
{
  "data": [
    {
      "name": "app-spec",
      "type": "directory",
      "size": 0,
      "modified_at": "2026-07-05 14:30",
      "is_binary": false
    },
    {
      "name": "README.md",
      "type": "file",
      "size": 2048,
      "modified_at": "2026-07-06 09:15",
      "is_binary": false
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | yes | File or directory name |
| type | string | yes | `"file"` or `"directory"` |
| size | integer | yes | File size in bytes (0 for directories) |
| modified_at | string | no | Last modified timestamp (displayed as-is) |
| is_binary | boolean | yes | Whether the file is binary (defaults to `false`) |

**Error responses:**

| Status | Condition |
|--------|-----------|
| 401 | Missing or invalid bearer token |
| 403 | Permission denied on path |
| 404 | Path not found |
| 500 | Server error |

### Client Behavior (Hermex)

- `directoryContentsProvider(path)` (FutureProvider.family) fetches per path
- Returns empty list when no server connected
- Breadcrumb trail navigation
- ".." parent folder navigation
- Pull-to-refresh and manual refresh button

---

## GET /v1/workspace/{path}

Returns directory listing OR file content for a specific path.

### Directory Request

```
GET /v1/workspace/app-spec/src
Authorization: Bearer <token>
```

### Directory Response

Same shape as root listing: `{ "data": [ { ...WorkspaceEntry }, ... ] }`

### File Request

```
GET /v1/workspace/app-spec/README.md
Authorization: Bearer <token>
```

### File Response

**200 OK** — Returns file content as a string in `data` or `content` field:

```json
{
  "data": "# Project Title\n\nThis is the README content..."
}
```

OR directly as a string (server-dependent):

```json
{
  "content": "# Project Title\n\nThis is the README content..."
}
```

| Field | Type | Description |
|-------|------|-------------|
| data | string/array | File content string for files, array of entries for directories |
| content | string | Alternative field for file content |

**Error responses:**

| Status | Condition |
|--------|-----------|
| 400 | Path is a directory (client detects and redirects to listing) |
| 401 | Missing or invalid bearer token |
| 403 | Permission denied |
| 404 | Path not found |
| 415 | Binary file — client shows "Cannot preview binary file" |

### Client Behavior (Hermex)

- `fileContentProvider(path)` (FutureProvider.family) fetches per path
- Binary files: client detects and shows warning (no content display)
- Directory paths: navigates into directory instead of showing content
- Monospace font for file preview
- Selectable text for copy-paste
- Close button to dismiss preview

---

## GET /api/jobs

Returns a paginated list of cron jobs.

### Request

```
GET /api/jobs
Authorization: Bearer ***
```

| Query Param | Type | Required | Default | Description |
|---|---|---|---|---|
| `per_page` | integer | no | 50 | Number of jobs per page |

No request body.

### Response

**200 OK** — Returns a JSON array of job objects:

```json
[
  {
    "id": "job_abc123",
    "name": "Daily Backup",
    "schedule": "0 9 * * *",
    "status": "active",
    "created_at": "2026-07-01T08:00:00Z"
  }
]
```

| Field | Type | Required | Description |
|---|---|---|---|
| id | string | yes | Unique job identifier |
| name | string | yes | Human-readable job name |
| schedule | string | yes | Cron expression |
| status | string | yes | `active` or `paused` |

**Error responses:**

| Status | Condition |
|---|---|
| 401 | Missing or invalid bearer token |
| 500 | Server error |

### Client Behavior (Hermex)

- `taskProvider` (Notifier) fetches on screen mount
- Returns empty list when no server connected
- "Paused" state shown with `pause_circle` icon
- Pull-to-refresh supported
- Jobs default to sorting by creation date (newest first)

---

## Cross-Cutting Rules

| Rule | Detail |
|------|--------|
| Auth | All endpoints use `Authorization: Bearer <hermes-api-key>` header |
| Read-only | `/v1/memory`, `/v1/insights`, `/v1/workspace` are GET-only — no mutations via the mobile client |
| Client resilience | All providers handle: no-server, empty, error, malformed response, and nested wrapping |
| Magic strings | All endpoint paths centralized in `ApiEndpoints` class |
| Spec gap prevention | LL-010: any new endpoint added to implementation MUST update this file in the same PR |
