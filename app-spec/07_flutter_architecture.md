# 07 — Flutter Architecture: Hermex Android

## Architecture Pattern: Clean Architecture + Riverpod

```
lib/
├── main.dart                     # Entry point, ProviderScope
├── app.dart                      # MaterialApp.router, theme
│
├── core/
│   ├── api/
│   │   ├── api_client.dart       # Dio instance, interceptors, auth
│   │   ├── sse_client.dart       # Raw HTTP SSE streaming client
│   │   ├── endpoints.dart        # All API path constants
│   │   └── api_exception.dart    # Typed exceptions
│   ├── auth/
│   │   └── auth_manager.dart     # Bearer token management
│   ├── storage/
│   │   ├── secure_storage.dart   # flutter_secure_storage wrapper
│   │   └── preferences.dart      # SharedPreferences wrapper
│   ├── theme/
│   │   ├── app_theme.dart        # Material 3 dark theme
│   │   ├── colors.dart           # Navy #001F5E, Cyan #32C2FF
│   │   └── typography.dart       # Text styles
│   ├── router/
│   │   └── app_router.dart       # GoRouter configuration
│   └── utils/
│       ├── markdown_renderer.dart # Flutter Markdown config
│       └── date_formatter.dart
│
├── features/
│   ├── connection/
│   │   ├── presentation/
│   │   │   ├── connection_screen.dart
│   │   │   └── server_list_screen.dart
│   │   ├── providers/
│   │   │   └── connection_provider.dart
│   │   └── data/
│   │       └── server_repository.dart
│   │
│   ├── chat/
│   │   ├── presentation/
│   │   │   ├── chat_screen.dart
│   │   │   ├── chat_input.dart
│   │   │   ├── message_bubble.dart
│   │   │   └── model_selector.dart
│   │   ├── providers/
│   │   │   ├── chat_provider.dart
│   │   │   └── stream_provider.dart
│   │   └── data/
│   │       ├── chat_repository.dart
│   │       └── chat_message.dart
│   │
│   ├── sessions/
│   │   ├── presentation/
│   │   │   ├── session_list_screen.dart
│   │   │   └── session_detail_screen.dart
│   │   ├── providers/
│   │   │   └── session_provider.dart
│   │   └── data/
│   │       └── session_repository.dart
│   │
│   ├── tasks/
│   │   ├── presentation/
│   │   │   ├── task_list_screen.dart
│   │   │   └── task_detail_screen.dart
│   │   ├── providers/
│   │   │   └── task_provider.dart
│   │   └── data/
│   │       └── task_repository.dart
│   │
│   ├── skills/
│   │   ├── presentation/
│   │   │   └── skills_screen.dart
│   │   ├── providers/
│   │   │   └── skills_provider.dart
│   │   └── data/
│   │       └── skills_repository.dart
│   │
│   ├── workspace/
│   │   ├── presentation/
│   │   │   └── workspace_screen.dart
│   │   ├── providers/
│   │   │   └── workspace_provider.dart
│   │   └── data/
│   │       └── workspace_repository.dart
│   │
│   ├── memory/
│   │   ├── presentation/
│   │   │   └── memory_screen.dart
│   │   └── providers/
│   │       └── memory_provider.dart
│   │
│   ├── insights/
│   │   ├── presentation/
│   │   │   └── insights_screen.dart
│   │   └── providers/
│   │       └── insights_provider.dart
│   │
│   └── settings/
│       ├── presentation/
│       │   └── settings_screen.dart
│       └── providers/
│           └── settings_provider.dart
│
└── models/
    ├── server_config.dart
    ├── model_info.dart
    ├── session_summary.dart
    ├── chat_message.dart
    ├── cron_job.dart
    ├── skill.dart
    ├── stream_event.dart
    └── api_response.dart
```

## State Management: Riverpod

```dart
// Providers hierarchy
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(activeServerProvider);
  return ApiClient(baseUrl: config.url, apiKey: config.apiKey);
});

final chatProvider = AsyncNotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});

final sessionListProvider = FutureProvider<List<SessionSummary>>((ref) {
  final api = ref.watch(apiClientProvider);
  return api.getSessions();
});
```

## SSE Streaming Architecture

```dart
class SseClient {
  // Uses dart:io HttpClient for raw HTTP streaming
  // Parses SSE format: "data: {...}\n\n"
  // Emits Stream<StreamEvent> via StreamController
  
  Stream<StreamEvent> connect(Uri uri, {Map<String, String>? headers});
  void cancel(String streamId);
}
```

## Navigation: GoRouter

```dart
GoRouter(
  initialLocation: '/connection',
  routes: [
    GoRoute(path: '/connection', builder: ...),
    GoRoute(path: '/chat', builder: ...),
    GoRoute(path: '/sessions', builder: ...),
    GoRoute(path: '/sessions/:id', builder: ...),
    GoRoute(path: '/tasks', builder: ...),
    GoRoute(path: '/tasks/:id', builder: ...),
    GoRoute(path: '/skills', builder: ...),
    GoRoute(path: '/workspace', builder: ...),
    GoRoute(path: '/memory', builder: ...),
    GoRoute(path: '/insights', builder: ...),
    GoRoute(path: '/settings', builder: ...),
  ],
)
```

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  # Navigation
  go_router: ^14.0.0
  # Networking
  dio: ^5.4.0
  # Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  # UI
  flutter_markdown: ^0.7.0
  google_fonts: ^6.1.0
  # Utilities
  uuid: ^4.3.0
  intl: ^0.19.0
  json_annotation: ^4.8.0
  freezed_annotation: ^2.4.0
  # Hermes brand
  material_color_utilities: ^0.11.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
  freezed: ^2.4.0
  isar_generator: ^3.1.0
  flutter_lints: ^4.0.0
```
