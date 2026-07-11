/// Feature flags — gate features pending backend endpoint support.
///
/// Set to `true` when the corresponding backend endpoint is confirmed available.
/// All gated code is searchable via `FEATURE_GATE:` comments.
abstract class FeatureFlags {
  FeatureFlags._();

  /// Gate /v1/insights until the Hermes Agent API Server supports it.
  /// BUG-5-Insights: gateway returns 404 for GET /v1/insights.
  /// Re-enable when the server is updated.
  static const bool insightsEnabled = false;

  /// Gate /v1/memory until the Hermes Agent API Server supports it.
  /// BUG-N2-Memory: gateway returns 404 for GET /v1/memory.
  /// Re-enable when the server is updated.
  static const bool memoryEnabled = false;

  /// Gate /v1/workspace until the Hermes Agent API Server supports it.
  /// BUG-N2-Workspace: gateway returns 404 for GET /v1/workspace.
  /// Re-enable when the server is updated.
  static const bool workspaceEnabled = false;
}

/// All GoRouter route path constants.
/// Centralized — no magic strings in navigation.
abstract class RoutePaths {
  RoutePaths._();

  // ─── Primary routes ───
  static const String connection = '/connection';
  static const String chat = '/chat';
  static const String sessions = '/sessions';
  static const String sessionDetail = '/sessions/:id';
  static const String tasks = '/tasks';
  static const String taskDetail = '/tasks/:id';
  static const String skills = '/skills';
  static const String workspace = '/workspace';
  static const String memory = '/memory';
  static const String insights = '/insights';
  static const String settings = '/settings';
  static const String servers = '/servers';
  static const String license = '/settings/license';

  // ─── Helpers ───

  /// Build a session detail path with the given [id].
  static String sessionById(String id) => '/sessions/$id';

  /// Build a task detail path with the given [id].
  static String taskById(String id) => '/tasks/$id';

  /// Build a chat path with session context — carries [id], optional [title],
  /// and optional [modelName] as query parameters so the ChatScreen can load
  /// history and display context in the AppBar.
  static String chatWithSession({
    required String id,
    String? title,
    String? modelName,
  }) {
    final params = <String>['session=$id'];
    if (title != null && title.isNotEmpty) {
      params.add('title=${Uri.encodeComponent(title)}');
    }
    if (modelName != null && modelName.isNotEmpty) {
      params.add('model=${Uri.encodeComponent(modelName)}');
    }
    return '/chat?${params.join('&')}';
  }
}
