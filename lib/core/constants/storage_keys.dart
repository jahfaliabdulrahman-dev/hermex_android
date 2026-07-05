/// Centralized storage key constants for secure storage and shared preferences.
/// No magic strings anywhere in storage operations.
abstract class StorageKeys {
  StorageKeys._();

  // ─── Secure Storage Keys ───
  static const String serverConfigs = 'server_configs';
  static const String activeServerId = 'active_server_id';

  /// Build an API key storage key for a given server ID.
  static String apiKeyFor(String serverId) => 'api_key_$serverId';

  // ─── Shared Preferences Keys ───
  static const String themeMode = 'theme_mode';
  static const String defaultModel = 'default_model';
  static const String defaultServerId = 'default_server_id';
  static const String lastSyncTimestamp = 'last_sync_timestamp';

  // ─── Isar ───
  static const String databaseName = 'hermex_cache';
}
