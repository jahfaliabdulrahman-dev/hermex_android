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
}
