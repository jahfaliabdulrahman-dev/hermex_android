# Hermex Android

Flutter mobile client for **Hermes Agent API Server** — a native control plane for your self-hosted Hermes Agent.

> **Your server. Your phone. No middleman.**

## What This Is

Hermex Android connects directly to Hermes Agent's built-in OpenAI-compatible API Server on port 8642. No middleware, no cloud — all data stays between your phone and your own server.

## Features

- **Chat** — Real-time SSE streaming chat with model selection and markdown rendering
- **Sessions** — Browse, search, create, rename, fork, archive, and pin chat sessions
- **Tasks** — Manage cron jobs: create, edit, pause, resume, run now, view output
- **Skills** — Browse installed agent skills, search/filter by category, toggle on/off
- **Workspace** — Browse server file system with directory listing, navigation, file preview
- **Memory & Insights** — View agent memory entries and usage statistics dashboard
- **Settings** — Manage multiple server profiles, theme (dark/light), model preferences, Hermes Agent profile switching

## Requirements

### Hermes Agent API Server

The app requires a running Hermes Agent with the API Server enabled:

```bash
# In your ~/.hermes/.env:
API_SERVER_ENABLED=true
API_SERVER_PORT=8642
API_SERVER_KEY=<your-bearer-token>
```

### Platform

| Platform | Minimum Version |
|----------|----------------|
| Android | 8.0 (API 26) |
| iOS | 16+ |

### Flutter SDK

- Dart SDK: ^3.11.4
- Flutter: Latest stable

## Getting Started

### 1. Clone the repository

```bash
git clone <repo-url> hermex_android
cd hermex_android
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Generate code

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run on device

```bash
# Android
flutter run

# iOS
flutter run -d ios
```

### 5. Build APK

```bash
flutter build apk --release
```

## Architecture

```
Clean Architecture + Riverpod + GoRouter + Dio
```

| Concern | Technology |
|---------|-----------|
| Framework | Flutter |
| State Management | Riverpod (Notifier + AsyncNotifier) |
| Navigation | GoRouter (declarative routing + deep linking) |
| Networking | Dio (REST) + raw `dart:io HttpClient` (SSE streaming) |
| Local Storage | flutter_secure_storage (API keys) + Isar (session cache) + SharedPreferences (settings) |
| Design System | Material 3 dark theme (navy #001F5E, cyan #32C2FF) |
| Code Generation | freezed + json_serializable + riverpod_generator |

### Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── api/          # ApiClient, SseClient, Endpoints, Exceptions
│   ├── auth/         # AuthManager (Bearer token)
│   ├── constants/    # Route paths, storage keys, strings
│   ├── providers/    # Top-level Riverpod providers
│   ├── router/       # GoRouter configuration
│   ├── storage/      # SecureStorage, Preferences
│   ├── theme/        # Colors, Typography, AppTheme
│   └── utils/        # Markdown renderer, date formatter
├── data/
│   ├── datasources/  # Isar provider
│   └── models/       # CachedSession, UserPreference
├── features/
│   ├── connection/   # F-001: Server connection
│   ├── chat/         # F-002: SSE streaming chat
│   ├── sessions/     # F-003: Session management
│   ├── tasks/        # F-004: Cron jobs
│   ├── skills/       # F-005: Skills browser
│   ├── workspace/    # F-006: Workspace browser
│   ├── memory/       # F-007: Memory viewer
│   ├── insights/     # F-007: Usage insights
│   └── settings/     # F-008: Settings
└── models/           # Domain models (freezed)
```

## Spec Pack

Full specifications in `app-spec/` (22 files). See `app-spec/00_project_context.md` for project overview.

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

Test layers:
- Unit tests — Providers, repositories, API parsing
- Widget tests — UI components, screen states
- Integration tests — Full flow (future)

## License

MIT — Free and open source. No analytics, no tracking, no third-party relay. All data stays between your phone and your own server.
