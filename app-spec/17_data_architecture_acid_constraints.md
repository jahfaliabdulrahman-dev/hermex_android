# 17 — Data Architecture & ACID Constraints

## Architecture: Thin Client
Hermex Android is primarily a **thin client**. The Hermes Agent API Server is the source of truth for all data. Local persistence is limited to caching and preferences.

## Local Storage

| Entity | Storage | Encryption | Purpose |
|--------|---------|------------|---------|
| ServerConfig | flutter_secure_storage | ✅ OS-level | Connection details |
| CachedSession | Isar DB | ❌ | Offline session list |
| UserPreference | SharedPreferences | ❌ | Theme, defaults |

## Data Integrity Rules
1. API key NEVER logged, NEVER stored in plaintext
2. Server URL validated before connection attempt
3. Session cache invalidated after 7 days
4. Offline cache is read-only — server is source of truth
