# 06 — API Contract (OpenAPI)

> Hermes Agent API Server is OpenAI-compatible. Full spec: `hermes-agent/website/docs/user-guide/features/api-server.md`
>
> **Last Updated:** 2026-07-12 (added pause/resume, run, delete, PATCH endpoints; corrected GET /api/jobs response shape — DEC-T2-PAUSERESUME)

## Key Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | /health | Health check |
| POST | /v1/chat/completions | Chat (streaming + non-streaming) |
| POST | /v1/responses | Responses API (stateful) |
| GET | /v1/models | Available models |
| GET | /api/sessions | Session list |
| POST | /api/sessions/{id}/chat/stream | SSE streaming turn |
| GET | /api/jobs | Cron job list (wrapped in `jobs` key) |
| POST | /api/jobs | Create cron job |
| PATCH | /api/jobs/{id} | Update cron job (name, prompt, schedule, enabled, skills, etc.) |
| POST | /api/jobs/{id}/pause | Pause a cron job |
| POST | /api/jobs/{id}/resume | Resume a paused cron job |
| POST | /api/jobs/{id}/run | Trigger immediate run |
| DELETE | /api/jobs/{id} | Delete a cron job |
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

Returns a paginated list of cron jobs wrapped in a `jobs` key. Returns all jobs regardless of status (active, paused, scheduled, etc.).

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

**200 OK** — Returns a JSON object with a `jobs` array:

```json
{
  "jobs": [
    {
      "id": "6b6068d51806",
      "name": "Daily Backup",
      "prompt": "Run backup",
      "schedule": {"kind": "cron", "expr": "0 9 * * *", "display": "0 9 * * *"},
      "state": "scheduled",
      "enabled": true,
      "paused_at": null,
      "last_run_at": null,
      "next_run_at": "2026-07-12T04:00:00+03:00",
      "created_at": "2026-07-12T00:32:56.603533+03:00",
      "last_error": null,
      "skills": [],
      "provider": null,
      "model": null,
      "deliver": "local"
    }
  ]
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| id | string | yes | Unique job identifier |
| name | string | yes | Human-readable job name |
| prompt | string | yes | The job's prompt/task to execute |
| schedule | object/string | yes | Schedule spec: `{"kind":"cron","expr":"...","display":"..."}` or `{"kind":"interval","minutes":N,"display":"..."}` |
| state | string | yes | Job state: `scheduled`, `paused`, `running`, etc. |
| enabled | boolean | yes | Whether the job is enabled |
| paused_at | ISO 8601 \| null | yes | Non-null when paused; null when not paused |
| last_run_at | ISO 8601 \| null | no | Timestamp of last execution |
| next_run_at | ISO 8601 \| null | no | Timestamp of next scheduled run |
| created_at | ISO 8601 | yes | Creation timestamp |
| last_error | string \| null | no | Last error message if any |
| skills | string[] | yes | List of skill names (empty array if none) |
| provider | string \| null | no | Model provider override |
| model | string \| null | no | Model name override |
| deliver | string | yes | Delivery target (default: `"local"`) |

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

## POST /api/jobs

Creates a new cron job.

### Request

```
POST /api/jobs
Authorization: Bearer ***
Content-Type: application/json

{"prompt": "Daily summary", "schedule": "0 9 * * *", "name": "Morning Brief"}
```

| Body Field | Type | Required | Description |
|---|---|---|---|
| prompt | string | yes | The task for the agent to execute |
| schedule | string | yes | Cron expression (e.g. `"0 9 * * *"`) or interval (e.g. `"30m"`) |
| name | string | no | Human-readable name |
| skills | string[] | no | Skill names to load |
| model_provider | string | no | Model provider |
| model_name | string | no | Model name |
| deliver | string | no | Delivery target |

### Response

**200 OK** — Returns `{"job": {...}}` with the created job (server-assigned ID).

---

## PATCH /api/jobs/{id}

Partially updates a cron job. Only sends the fields to change.

**IMPORTANT:** The `paused` field is NOT accepted — use the action endpoints below for pause/resume.

### Accepted Fields

| Field | Type | Description |
|---|---|---|
| name | string | Rename the job |
| prompt | string | Update the task prompt |
| schedule | string | Update the cron expression |
| skills | string[] | Update skill list |
| enabled | boolean | Enable/disable (does NOT set paused_at) |
| model_provider | string | Model provider |
| model_name | string | Model name |
| deliver | string | Delivery target |

### Response

**200 OK** — Returns `{"job": {...}}` with the updated job.
**400** — `{"error": "No valid fields to update"}` when sending unsupported fields.

---

## POST /api/jobs/{id}/pause

Pauses a cron job (DEC-T2-PAUSERESUME).

### Request

```
POST /api/jobs/{id}/pause
Authorization: Bearer ***
```

No request body.

### Response

**200 OK** — Returns `{"job": {...}}` with `state: "paused"`, `enabled: false`, `paused_at` set.

---

## POST /api/jobs/{id}/resume

Resumes a paused cron job (DEC-T2-PAUSERESUME).

### Request

```
POST /api/jobs/{id}/resume
Authorization: Bearer ***
```

No request body.

### Response

**200 OK** — Returns `{"job": {...}}` with `state: "scheduled"`, `enabled: true`, `paused_at: null`.

---

## POST /api/jobs/{id}/run

Triggers an immediate execution of a cron job.

### Request

```
POST /api/jobs/{id}/run
Authorization: Bearer ***
```

No request body.

### Response

**200 OK** — Returns `{"job": {...}}` with updated job state.

---

## DELETE /api/jobs/{id}

Deletes a cron job.

### Request

```
DELETE /api/jobs/{id}
Authorization: Bearer ***
```

### Response

**200 OK** — `{"ok": true}`

---

## Cross-Cutting Rules

| Rule | Detail |
|------|--------|
| Auth | All endpoints use `Authorization: Bearer <hermes-api-key>` header |
| Read-only | `/v1/memory`, `/v1/insights`, `/v1/workspace` are GET-only — no mutations via the mobile client |
| Client resilience | All providers handle: no-server, empty, error, malformed response, and nested wrapping |
| Magic strings | All endpoint paths centralized in `ApiEndpoints` class |
| Spec gap prevention | LL-010: any new endpoint added to implementation MUST update this file in the same PR |
