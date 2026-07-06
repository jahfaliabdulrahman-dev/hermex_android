# 05 — Data Model & ERD: Hermex Android

## Overview

Hermex Android is primarily a **thin client** — the server (Hermes Agent API Server) is the source of truth. Local persistence is limited to:

1. **Server configurations** — encrypted connection details
2. **Session cache** — offline-accessible session list
3. **User preferences** — theme, default model, etc.

## Entities

### ServerConfig
```
ServerConfig {
  id: String (UUID)
  name: String
  url: String (e.g., "http://192.168.1.100:8642")
  apiKey: String (encrypted at rest)
  isDefault: bool
  lastConnected: DateTime?
  createdAt: DateTime
}
```

### CachedSession
```
CachedSession {
  id: String (server session ID)
  serverId: String (FK → ServerConfig.id)
  title: String?
  modelName: String?
  messageCount: int
  lastActivity: DateTime
  isPinned: bool
  isArchived: bool
  cachedAt: DateTime
}
```

### UserPreference
```
UserPreference {
  key: String ("theme", "default_model", "default_server")
  value: String
  updatedAt: DateTime
}
```

## API Models (Server-Sourced)

All other models come from the Hermes Agent API Server and are NOT persisted locally. They are data classes only:

```dart
// From GET /v1/models
class ModelInfo {
  final String id;
  final String object;
  final int created;
  final String ownedBy;
}

// From GET /api/sessions
class SessionSummary {
  final String id;
  final String? title;
  final String? modelName;
  final int messageCount;
  final DateTime createdAt;
  final DateTime? lastActivity;
  final bool isPinned;
  final bool isArchived;
  final String? status;
}

// From GET /api/sessions/{id}/messages
class ChatMessage {
  final String role; // "user" | "assistant" | "system" | "tool"
  final String content;
  final String? toolCallId;
  final String? toolName;
  final DateTime? timestamp;
  final List<ToolCall>? toolCalls;
}

// From GET /api/jobs
class CronJob {
  final String id;
  final String prompt;
  final String schedule;
  final String? status;
  final DateTime? lastRun;
  final DateTime? nextRun;
  final List<String>? skills;
  final String? modelProvider;
  final String? modelName;
}

// From GET /v1/skills
class Skill {
  final String name;
  final String description;
  final String? category;
  final bool enabled;
}

// From GET /v1/workspace and GET /v1/workspace/{path}
// Implementation: @freezed + json_serializable
// JSON keys: name, type, size, modified_at, is_binary
@freezed
class WorkspaceEntry {
  final String name;                         // required
  @Default('file') final String type;        // 'file' | 'directory'
  @Default(0) final int size;                // bytes, 0 for directories
  @JsonKey(name: 'modified_at') final String? modifiedAt;  // ISO 8601
  @JsonKey(name: 'is_binary') @Default(false) final bool isBinary;
}

// From GET /v1/memory
// Implementation: plain Dart (not Freezed) with safe JSON parsing.
// Handles malformed payloads: falls back to 'key'/'name' for title,
// 'key' for id, nested {memories: [...]} or {data: [...]} wrapping.
class MemoryEntry {
  final String id;              // required; falls back to json['key']
  final String title;           // required; falls back to json['key'] → json['name'] → 'Untitled'
  final String? description;    // nullable
  final DateTime? createdAt;    // parsed from created_at or createdAt
  final DateTime? updatedAt;    // parsed from updated_at or updatedAt

  static List<MemoryEntry> parseList(dynamic body);  // handles List or Map wrapper
}

// From GET /v1/insights
// Implementation: plain Dart (not Freezed) with safe JSON parsing.
// Handles nested {insights: {...}} or {data: {...}} wrapping.
// Computed props: formattedActiveTime ("Xh Ym"), formattedTokens ("1.2k" / "3.5M").
class InsightsData {
  @Default(0) final int totalSessions;
  @Default(0) final int totalMessages;
  @Default(0) final int totalTokens;
  @Default(0) final int activeTimeMinutes;   // minutes
  final DateTime? lastSynced;               // parsed from last_synced
  @Default(0) final int cronJobsRun;
  @Default(0) final int skillsCount;

  String get formattedActiveTime;           // "0m" / "2h 30m" / "45m"
  String get formattedTokens;               // "0" / "1.2k" / "3.5M"
  static InsightsData parse(dynamic body);  // handles Map or nested wrapping
}

// SSE Events
sealed class StreamEvent {
  // ChatCompletions: choices[0].delta.content
  // Responses: response.output_text.delta
}

class TextDelta extends StreamEvent {
  final String text;
}

class ToolProgress extends StreamEvent {
  final String toolName;
  final String status; // "started" | "completed"
}

class StreamDone extends StreamEvent {}

class StreamError extends StreamEvent {
  final String message;
}
```

## Data Flow

```
User Action → Riverpod Provider → API Service (Dio) → Hermes Agent API Server
                                                              ↓
UI Update ← State Update ← Model Parser ← JSON Response/SSE Stream
```

## Local Storage Strategy

| Data | Storage | Encryption | TTL |
|------|---------|------------|-----|
| Server configs | flutter_secure_storage | ✅ OS-level | Permanent |
| Session cache | Isar DB | ❌ (non-sensitive) | 7 days |
| User prefs | SharedPreferences | ❌ | Permanent |
| API keys | flutter_secure_storage | ✅ OS-level | Permanent |

---
*Last updated: 2026-07-06 — FIX: Enhanced WorkspaceEntry, MemoryEntry, InsightsData with Freezed annotations, JSON key mappings, default values, safe-parsing notes, static helpers, and computed properties. Ref: t_98123697.*
