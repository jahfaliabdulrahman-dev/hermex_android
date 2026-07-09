import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized SharedPreferences keys — no magic strings.
abstract class PrefKeys {
  static const themeMode = 'theme_mode';
  static const defaultModel = 'default_model';
  static const defaultServerId = 'default_server_id';
  static const lastSyncTimestamp = 'last_sync_timestamp';
}

/// Thin wrapper around SharedPreferences for simple user preferences.
///
/// For structured, queryable preferences, use the UserPreference Isar model.
/// This wrapper is for fast-access, single-value preferences (theme, defaults).
class AppPreferences {
  final SharedPreferences _prefs;

  AppPreferences(this._prefs);

  // ─── Theme Mode ───

  /// Returns 'system', 'light', or 'dark'. Defaults to 'dark' (Hermes brand default, EPIC-001).
  String get themeMode => _prefs.getString(PrefKeys.themeMode) ?? 'dark';

  Future<bool> setThemeMode(String mode) =>
      _prefs.setString(PrefKeys.themeMode, mode);

  // ─── Default Model ───

  String? get defaultModel => _prefs.getString(PrefKeys.defaultModel);

  Future<bool> setDefaultModel(String modelId) =>
      _prefs.setString(PrefKeys.defaultModel, modelId);

  // ─── Default Server ID ───

  String? get defaultServerId => _prefs.getString(PrefKeys.defaultServerId);

  Future<bool> setDefaultServerId(String serverId) =>
      _prefs.setString(PrefKeys.defaultServerId, serverId);

  // ─── Last Sync ───

  int? get lastSyncTimestampMs =>
      _prefs.getInt(PrefKeys.lastSyncTimestamp);

  Future<bool> setLastSyncNow() =>
      _prefs.setInt(PrefKeys.lastSyncTimestamp, DateTime.now().millisecondsSinceEpoch);
}

/// Riverpod provider — initialized once with SharedPreferences instance.
final appPreferencesProvider = Provider<AppPreferences>((ref) {
  throw UnimplementedError(
    'appPreferencesProvider must be overridden in ProviderScope '
    'after SharedPreferences.getInstance() completes.',
  );
});

/// Initialize SharedPreferences before runApp.
Future<SharedPreferences> initPreferences() =>
    SharedPreferences.getInstance();
