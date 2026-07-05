import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/server_config.dart';

/// Thin wrapper around flutter_secure_storage for ServerConfig + API key storage.
///
/// SECURITY RULES (from spec 05_data_model_erd.md, 17_data_architecture_acid_constraints.md):
/// 1. API key NEVER logged, NEVER stored in plaintext
/// 2. All values are OS-encrypted (Keychain on iOS, EncryptedSharedPreferences on Android)
/// 3. API key is read/written atomically — no partial state
class SecureStorage {
  static const _storage = FlutterSecureStorage();

  // ─── Key Constants (centralized — no magic strings) ───

  static const _kServerConfigsKey = 'server_configs';
  static const _kActiveServerIdKey = 'active_server_id';

  // ─── Server Configs (JSON-encoded list) ───

  // ─── Task-required domain interface ───

  /// Save a single ServerConfig. Adds or updates the config in the stored list.
  /// Returns the updated list of all configs.
  Future<List<ServerConfig>> saveServerConfig(ServerConfig config) async {
    final configs = await getServerConfigs();
    final index = configs.indexWhere((c) => c.id == config.id);
    if (index >= 0) {
      configs[index] = config;
    } else {
      configs.add(config);
    }
    await writeServerConfigsRaw(jsonEncode(configs.map((c) => c.toJson()).toList()));
    return configs;
  }

  /// Get all saved ServerConfig objects. Returns empty list if none stored.
  Future<List<ServerConfig>> getServerConfigs() async {
    final raw = await readServerConfigsRaw();
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ServerConfig.fromJson(e as Map<String, dynamic>))
        .where((c) => !c.isDeleted) // Filter out soft-deleted configs
        .toList();
  }

  // ─── Lower-level raw operations ───

  /// Read all server configs as raw JSON string. Returns null if none stored.
  Future<String?> readServerConfigsRaw() async {
    return _storage.read(key: _kServerConfigsKey);
  }

  /// Write server configs as a JSON-encoded string.
  Future<void> writeServerConfigsRaw(String json) async {
    await _storage.write(key: _kServerConfigsKey, value: json);
  }

  /// Delete all server configs from secure storage.
  Future<void> deleteServerConfigs() async {
    await _storage.delete(key: _kServerConfigsKey);
  }

  // ─── Active Server ID ───

  /// Read the active (last connected) server ID.
  Future<String?> readActiveServerId() async {
    return _storage.read(key: _kActiveServerIdKey);
  }

  /// Set the active server ID.
  Future<void> writeActiveServerId(String serverId) async {
    await _storage.write(key: _kActiveServerIdKey, value: serverId);
  }

  // ─── API Key (per-server) — Task-required interface ───

  /// Save an API key for a specific server. (Alias for writeApiKey)
  ///
  /// WARNING: The [apiKey] value must NOT be logged or stored in plaintext
  /// anywhere outside this secure storage.
  Future<void> saveApiKey(String serverId, String apiKey) =>
      writeApiKey(serverId, apiKey);

  /// Get the API key for a specific server. (Alias for readApiKey)
  ///
  /// WARNING: Caller must NOT log, print, or serialize this value.
  Future<String?> getApiKey(String serverId) => readApiKey(serverId);

  /// Delete the API key for a specific server. (Alias for deleteApiKey — same impl)
  Future<void> deleteApiKeyFor(String serverId) => deleteApiKey(serverId);

  // ─── Lower-level API Key operations ───

  /// Read the API key for a specific server.
  /// Returns null if not set.
  ///
  /// WARNING: Caller must NOT log, print, or serialize this value.
  Future<String?> readApiKey(String serverId) async {
    return _storage.read(key: _apiKeyFor(serverId));
  }

  /// Write the API key for a specific server.
  ///
  /// WARNING: The [apiKey] value must NOT be logged or stored in plaintext
  /// anywhere outside this secure storage. This wrapper ensures OS-level
  /// encryption at rest.
  Future<void> writeApiKey(String serverId, String apiKey) async {
    await _storage.write(key: _apiKeyFor(serverId), value: apiKey);
  }

  /// Delete the API key for a specific server.
  Future<void> deleteApiKey(String serverId) async {
    await _storage.delete(key: _apiKeyFor(serverId));
  }

  /// Delete all stored data (configs, active server, all API keys).
  /// Used when clearing all server data.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // ─── Private ───

  static String _apiKeyFor(String serverId) => 'api_key_$serverId';
}
