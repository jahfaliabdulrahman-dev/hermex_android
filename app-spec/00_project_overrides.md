# 00 — Project Overrides: Hermex Android

## Overrides from FLUTTER_GLOBAL_CONTRACT.md

| Rule | Override | Reason |
|------|----------|--------|
| Database | Isar for offline cache only | Primary data from API server |
| Authentication | Bearer token (API_SERVER_KEY) | Hermes Agent API Server auth |
| Backend | Hermes Agent API Server (port 8642) | Not a custom backend |
| Soft Delete | N/A | Server manages session lifecycle |

## Technology Exceptions

| Technology | CarSah Default | Hermex Android | Reason |
|------------|---------------|----------------|--------|
| State | Riverpod | Riverpod | Same |
| DB | Isar | Isar (minimal) | Cache only |
| HTTP | Dio | Dio | Same |
| Streaming | N/A | Raw HttpClient SSE | New — no existing pattern |
