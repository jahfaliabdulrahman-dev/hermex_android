import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/endpoints.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../models/server_config.dart';

/// Repository for ServerConfig CRUD and connection health check operations.
///
/// Persistence: flutter_secure_storage (OS-encrypted) via SecureStorage.
/// Health check: creates a throwaway Dio instance for each attempt.
///
/// SECURITY: API keys are NEVER logged, printed, or serialized.
/// Repository owns its own transaction boundaries — no nested writeTxn.
class ServerRepository {
  final SecureStorage _secureStorage;
  final Uuid _uuid;

  ServerRepository({
    required SecureStorage secureStorage,
    Uuid? uuid,
  })  : _secureStorage = secureStorage,
        _uuid = uuid ?? const Uuid();

  // ─── CRUD ───

  /// Save (create or update) a server configuration.
  /// Returns the saved [ServerConfig].
  Future<ServerConfig> save(ServerConfig config) async {
    debugPrint(
        '=== HERMEX DEBUG: ServerRepository.save — id=${config.id}, name=${config.name} ===');
    await _secureStorage.saveServerConfig(config);
    return config;
  }

  /// Create a new server config with a generated UUID.
  /// Does NOT persist until [save] is called.
  ServerConfig createConfig({
    required String name,
    required String url,
    bool isDefault = false,
  }) {
    return ServerConfig(
      id: _uuid.v4(),
      name: name,
      url: url,
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );
  }

  /// Get all non-deleted server configurations.
  Future<List<ServerConfig>> getAll() async {
    debugPrint('=== HERMEX DEBUG: ServerRepository.getAll ===');
    return _secureStorage.getServerConfigs();
  }

  /// Get a specific server config by ID.
  Future<ServerConfig?> getById(String id) async {
    final configs = await getAll();
    return configs.cast<ServerConfig?>().firstWhere(
          (c) => c!.id == id,
          orElse: () => null,
        );
  }

  /// Soft-delete a server config (isDeleted = true, deletedAt = now).
  Future<void> softDelete(String id) async {
    debugPrint('=== HERMEX DEBUG: ServerRepository.softDelete — id=$id ===');
    final config = await getById(id);
    if (config == null) return;

    final deleted = config.copyWith(
      isDeleted: true,
      deletedAt: DateTime.now(),
    );
    await _secureStorage.saveServerConfig(deleted);

    // Delete associated API key from secure storage.
    await _secureStorage.deleteApiKey(id);
  }

  /// Hard-delete all data for a server (no soft delete — used when clearing all).
  Future<void> delete(String id) async {
    debugPrint('=== HERMEX DEBUG: ServerRepository.delete — id=$id ===');
    final configs = await getAll();
    configs.removeWhere((c) => c.id == id);

    // Re-save the filtered list.
    await _secureStorage.deleteServerConfigs();
    for (final config in configs) {
      await _secureStorage.saveServerConfig(config);
    }

    await _secureStorage.deleteApiKey(id);
    final activeId = await _secureStorage.readActiveServerId();
    if (activeId == id) {
      await _secureStorage.writeActiveServerId('');
    }
  }

  // ─── Active Server ───

  /// Get the currently active server config.
  Future<ServerConfig?> getActive() async {
    final activeId = await _secureStorage.readActiveServerId();
    if (activeId == null || activeId.isEmpty) return null;
    return getById(activeId);
  }

  /// Set a server as active.
  Future<void> setActive(String id) async {
    debugPrint('=== HERMEX DEBUG: ServerRepository.setActive — id=$id ===');
    await _secureStorage.writeActiveServerId(id);

    // Update lastConnected timestamp.
    final config = await getById(id);
    if (config != null) {
      final updated = config.copyWith(lastConnected: DateTime.now());
      await _secureStorage.saveServerConfig(updated);
    }
  }

  // ─── API Key ───

  /// Save the API key for a server ID.
  /// SECURITY: [apiKey] is NEVER logged.
  Future<void> saveApiKey(String serverId, String apiKey) async {
    debugPrint('=== HERMEX DEBUG: ServerRepository.saveApiKey — serverId=$serverId ===');
    await _secureStorage.saveApiKey(serverId, apiKey);
  }

  /// Get the API key for a server ID.
  /// SECURITY: caller must NOT log return value.
  Future<String?> getApiKey(String serverId) async {
    return _secureStorage.getApiKey(serverId);
  }

  // ─── Health Check ───

  /// Check if the given server URL is reachable and authenticated.
  ///
  /// Creates a throwaway Dio client with a 10-second timeout.
  /// Calls GET /health with Bearer auth.
  ///
  /// Returns a [HealthCheckResult] indicating success or failure reason.
  Future<HealthCheckResult> healthCheck({
    required String url,
    required String apiKey,
  }) async {
    debugPrint('=== HERMEX DEBUG: ServerRepository.healthCheck — url=$url ===');
    // NOTE: url is logged for debugging; apiKey is NEVER logged.

    final normalizedUrl = _normalizeUrl(url);

    // Validate URL format before attempting connection.
    final urlError = _validateUrl(normalizedUrl);
    if (urlError != null) {
      return HealthCheckResult.failure(
        HealthCheckFailure.invalidUrl,
        message: urlError,
      );
    }

    final dio = Dio(BaseOptions(
      baseUrl: normalizedUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ));

    try {
      final response = await dio.get(ApiEndpoints.health);
      debugPrint(
          '=== HERMEX DEBUG: Health check response — status=${response.statusCode} ===');

      if (response.statusCode == 200) {
        return HealthCheckResult.success();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return HealthCheckResult.failure(
          HealthCheckFailure.authFailed,
          message: 'Server returned ${response.statusCode} — check your API key.',
        );
      } else {
        return HealthCheckResult.failure(
          HealthCheckFailure.serverError,
          message:
              'Server returned ${response.statusCode}: ${response.statusMessage ?? "unexpected response"}.',
        );
      }
    } on DioException catch (e) {
      debugPrint(
          '=== HERMEX DEBUG: Health check DioException — type=${e.type}, message=${e.message} ===');
      return _mapDioError(e);
    } catch (e) {
      debugPrint(
          '=== HERMEX DEBUG: Health check unexpected error — $e ===');
      return HealthCheckResult.failure(
        HealthCheckFailure.unknown,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ─── URL Validation ───

  /// Normalize a server URL: trim whitespace, remove trailing slash.
  static String _normalizeUrl(String url) {
    var normalized = url.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  /// Validate URL format against RFC 3986 and enforce security rules.
  ///
  /// Rules:
  /// 1. URL must not be empty.
  /// 2. URL must be parseable as an absolute URI with a host.
  /// 3. Must use http:// or https:// scheme.
  /// 4. No userinfo (credentials) in URL — prevents host injection
  ///    like `http://evil.com@192.168.1.100:8642`.
  /// 5. HTTP scheme is only allowed for RFC 1918 private hosts
  ///    (localhost, 127.0.0.1, 192.168.x.x, 10.x.x.x, 172.16-31.x.x).
  ///    Remote connections MUST use HTTPS.
  ///
  /// Returns an error message string if invalid, null if valid.
  String? _validateUrl(String url) {
    if (url.isEmpty) {
      return 'Server URL cannot be empty.';
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority) {
      return AppStrings.invalidUrlNotAbsolute;
    }

    // RFC 3986 §3.2.1: reject userinfo in authority.
    // Dart's Uri parser separates userInfo from host — if userInfo is
    // non-empty, an `@` was present (e.g., http://evil.com@192.168.1.100:8642).
    if (uri.userInfo.isNotEmpty) {
      debugPrint(
          '=== HERMEX DEBUG: _validateUrl — rejected: userInfo present ===');
      return AppStrings.invalidUrlHostInjection;
    }

    // Require a host.
    if (uri.host.isEmpty) {
      return AppStrings.invalidUrlNotAbsolute;
    }

    // Require http:// or https:// scheme.
    final scheme = uri.scheme;
    if (scheme != 'http' && scheme != 'https') {
      return AppStrings.invalidUrlNoScheme;
    }

    // HTTP only allowed on local/RFC 1918 networks.
    if (scheme == 'http' && !isLocalNetwork(url)) {
      debugPrint(
          '=== HERMEX DEBUG: _validateUrl — rejected: HTTP on non-local host ===');
      return AppStrings.invalidUrlHttpRemote;
    }

    return null; // Valid — HTTPS or local-network HTTP.
  }
  HealthCheckResult _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return HealthCheckResult.failure(
          HealthCheckFailure.timeout,
          message: 'Connection timed out after 10 seconds. '
              'Check the URL and ensure the server is running.',
        );

      case DioExceptionType.connectionError:
        return HealthCheckResult.failure(
          HealthCheckFailure.unreachable,
          message: 'Cannot reach server. '
              'Check the URL and ensure Hermes Agent is running.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return HealthCheckResult.failure(
            HealthCheckFailure.authFailed,
            message: 'Authentication failed — check your API_SERVER_KEY.',
          );
        }
        return HealthCheckResult.failure(
          HealthCheckFailure.serverError,
          message: error.response?.statusMessage ?? 'Server error.',
        );

      default:
        return HealthCheckResult.failure(
          HealthCheckFailure.unknown,
          message: error.message ?? 'Connection failed.',
        );
    }
  }

  // ─── Local Network Detection ───

  /// Returns true if the URL appears to be on a local network.
  /// Pure function — no instance state required.
  static bool isLocalNetwork(String url) {
    final normalized = _normalizeUrl(url);
    final uri = Uri.tryParse(normalized);
    if (uri == null) return false;

    final host = uri.host.toLowerCase();
    // Common local host patterns
    if (host == 'localhost' || host == '127.0.0.1') return true;
    if (host.startsWith('192.168.')) return true;
    if (host.startsWith('10.')) return true;
    if (host.startsWith('172.') && _isPrivate172(host)) return true;

    return false;
  }

  /// Check if a 172.x.x.x address is in the private 172.16.0.0/12 range.
  static bool _isPrivate172(String host) {
    try {
      final parts = host.split('.');
      if (parts.length != 4) return false;
      final second = int.parse(parts[1]);
      return second >= 16 && second <= 31;
    } catch (_) {
      return false;
    }
  }
}

// ─── Health Check Result ───

/// Result of a server health check operation.
class HealthCheckResult {
  final bool isSuccess;
  final HealthCheckFailure? failure;
  final String? message;

  const HealthCheckResult._({
    required this.isSuccess,
    this.failure,
    this.message,
  });

  factory HealthCheckResult.success() =>
      const HealthCheckResult._(isSuccess: true);

  factory HealthCheckResult.failure(HealthCheckFailure failure,
          {String? message}) =>
      HealthCheckResult._(
        isSuccess: false,
        failure: failure,
        message: message ?? failure.defaultMessage,
      );
}

/// Categorized health check failure modes.
enum HealthCheckFailure {
  invalidUrl('Invalid server URL.'),
  unreachable('Server unreachable.'),
  timeout('Connection timed out.'),
  authFailed('Authentication failed.'),
  serverError('Server returned an error.'),
  unknown('Connection failed.');

  final String defaultMessage;
  const HealthCheckFailure(this.defaultMessage);
}
