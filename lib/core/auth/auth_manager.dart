import 'dart:convert';

import '../storage/secure_storage.dart';
import '../../models/server_config.dart';

/// Bearer token and active server management.
///
/// Loads/saves API keys from flutter_secure_storage (OS-encrypted).
/// Tracks the active server ID for multi-server support.
/// Provides the Bearer token and base URL for Dio interceptor configuration.
///
/// SECURITY: API key values are NEVER logged, printed, or serialized.
class AuthManager {
  final SecureStorage _secureStorage;

  AuthManager({required SecureStorage secureStorage})
      : _secureStorage = secureStorage;

  // ─── Active Server ───

  /// Get the currently active server ID.
  Future<String?> getActiveServerId() async {
    return _secureStorage.readActiveServerId();
  }

  /// Set the active server ID after successful connection.
  Future<void> setActiveServerId(String serverId) async {
    await _secureStorage.writeActiveServerId(serverId);
  }

  /// Get the active server's base URL.
  /// Returns null if no active server or config not found.
  Future<String?> getActiveServerUrl() async {
    final serverId = await getActiveServerId();
    if (serverId == null || serverId.isEmpty) return null;

    final raw = await _secureStorage.readServerConfigsRaw();
    if (raw == null) return null;

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        final config = item as Map<String, dynamic>;
        if (config['id'] == serverId && config['isDeleted'] != true) {
          return config['url'] as String?;
        }
      }
    } catch (_) {
      // Config parse failure — return null.
    }
    return null;
  }

  /// Get the active server's config.
  /// Returns null if no active server.
  Future<ServerConfig?> getActiveServerConfig() async {
    final serverId = await getActiveServerId();
    if (serverId == null || serverId.isEmpty) return null;

    final raw = await _secureStorage.readServerConfigsRaw();
    if (raw == null) return null;

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        final config = ServerConfig.fromJson(item as Map<String, dynamic>);
        if (config.id == serverId && !config.isDeleted) {
          return config;
        }
      }
    } catch (_) {
      // Config parse failure — return null.
    }
    return null;
  }

  /// Get the Bearer auth header value for the active server.
  /// Returns null if no active server or no API key stored.
  ///
  /// WARNING: Caller must NOT log or serialize the return value.
  Future<String?> getAuthHeader() async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;
    return 'Bearer $apiKey';
  }

  // ─── API Key ───

  /// Get the API key for the active server.
  /// Returns null if no active server or no key stored.
  ///
  /// WARNING: Caller must NOT log or serialize the return value.
  Future<String?> getApiKey() async {
    final serverId = await getActiveServerId();
    if (serverId == null) return null;
    return _secureStorage.getApiKey(serverId);
  }

  /// Get the API key for a specific server ID.
  ///
  /// WARNING: Caller must NOT log or serialize the return value.
  Future<String?> getApiKeyFor(String serverId) async {
    return _secureStorage.getApiKey(serverId);
  }

  /// Save the API key for a specific server.
  ///
  /// WARNING: [apiKey] must NOT be logged or stored in plaintext.
  Future<void> saveApiKey(String serverId, String apiKey) async {
    await _secureStorage.saveApiKey(serverId, apiKey);
  }

  /// Delete the API key for a specific server.
  Future<void> deleteApiKey(String serverId) async {
    await _secureStorage.deleteApiKey(serverId);
  }

  // ─── Convenience ───

  /// Check if any API key is stored for the active server.
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Clear all auth state (server ID + all API keys).
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
