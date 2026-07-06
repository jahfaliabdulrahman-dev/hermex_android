import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../models/server_config.dart';
import '../data/server_repository.dart';

/// UI state for the connection feature.
enum ConnectionStatus {
  /// No connection attempt in progress, no active server.
  idle,

  /// Health check in progress.
  connecting,

  /// Successfully connected to a server.
  connected,

  /// Connection attempt failed. [errorMessage] contains details.
  error,
}

/// Complete state for the connection feature.
class ServerConnectionState {
  /// Current connection status.
  final ConnectionStatus status;

  /// Active server config, if any.
  final ServerConfig? activeServer;

  /// All saved server configs (non-deleted).
  final List<ServerConfig> servers;

  /// Error message when status is [ConnectionStatus.error].
  final String? errorMessage;

  /// Whether the currently-entered URL looks like a local network address.
  final bool isLocalNetwork;

  /// Whether a save/delete operation is in progress.
  final bool isBusy;

  const ServerConnectionState({
    this.status = ConnectionStatus.idle,
    this.activeServer,
    this.servers = const [],
    this.errorMessage,
    this.isLocalNetwork = false,
    this.isBusy = false,
  });

  ServerConnectionState copyWith({
    ConnectionStatus? status,
    ServerConfig? activeServer,
    bool clearActiveServer = false,
    List<ServerConfig>? servers,
    String? errorMessage,
    bool clearError = false,
    bool? isLocalNetwork,
    bool? isBusy,
  }) =>
      ServerConnectionState(
        status: status ?? this.status,
        activeServer:
            clearActiveServer ? null : (activeServer ?? this.activeServer),
        servers: servers ?? this.servers,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        isLocalNetwork: isLocalNetwork ?? this.isLocalNetwork,
        isBusy: isBusy ?? this.isBusy,
      );
}

/// Notifier for server connection management.
///
/// Manages: server CRUD, health checks, active server tracking.
/// Uses [ServerRepository] for persistence and health check operations.
///
/// SECURITY: API keys are NEVER logged or exposed in state.
class ConnectionNotifier extends Notifier<ServerConnectionState> {
  late final ServerRepository _repository;

  @override
  ServerConnectionState build() {
    _repository = ServerRepository(secureStorage: SecureStorage());
    // Load servers on initialization.
    _loadServers();
    return const ServerConnectionState();
  }

  /// Load saved servers from secure storage.
  Future<void> _loadServers() async {
    final servers = await _repository.getAll();
    final active = await _repository.getActive();

    state = state.copyWith(
      servers: servers,
      activeServer: active,
      status: active != null ? ConnectionStatus.connected : ConnectionStatus.idle,
    );
  }

  /// Refresh the server list from storage.
  Future<void> refreshServers() async {
    await _loadServers();
  }

  // ─── Connection ───

  /// Attempt to connect to a server at [url] with [apiKey].
  ///
  /// Flow:
  /// 1. Validate URL format (locally)
  /// 2. Normalize URL (trim, remove trailing slash)
  /// 3. Perform health check (GET /health, 10s timeout)
  /// 4. On success: save server config + API key, set active, update state
  /// 5. On failure: update error state
  Future<bool> connect({
    required String url,
    required String apiKey,
    String? label,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: ConnectionNotifier.connect — url=$url ===');
    }

    // Prevent duplicate submissions.
    if (state.status == ConnectionStatus.connecting || state.isBusy) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: ConnectionNotifier.connect — blocked: already connecting ===');
      }
      return false;
    }

    state = state.copyWith(
      status: ConnectionStatus.connecting,
      errorMessage: null,
      clearError: true,
      isBusy: true,
    );

    // Detect local network.
    final isLocal = ServerRepository.isLocalNetwork(url);
    state = state.copyWith(isLocalNetwork: isLocal);

    // Perform health check.
    final result = await _repository.healthCheck(
      url: url,
      apiKey: apiKey,
    );

    if (!result.isSuccess) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: result.message,
        isBusy: false,
      );
      return false;
    }

    // Normalize URL for storage.
    final normalizedUrl = url.trim().endsWith('/')
        ? url.trim().substring(0, url.trim().length - 1)
        : url.trim();

    // Generate server name from label or URL.
    final serverName = (label != null && label.trim().isNotEmpty)
        ? label.trim()
        : _urlToDisplayName(normalizedUrl);

    // Check if a config with this URL already exists.
    final existingServers = await _repository.getAll();
    ServerConfig config;
    final existing = existingServers.cast<ServerConfig?>().firstWhere(
          (s) => s!.url == normalizedUrl,
          orElse: () => null,
        );

    if (existing != null) {
      // Update existing config.
      config = existing.copyWith(
        name: serverName,
        lastConnected: DateTime.now(),
      );
    } else {
      // Create new config.
      config = _repository.createConfig(
        name: serverName,
        url: normalizedUrl,
        isDefault: existingServers.isEmpty, // First server is default.
      );
    }

    // Persist server config and API key.
    await _repository.save(config);
    await _repository.saveApiKey(config.id, apiKey);
    await _repository.setActive(config.id);

    // Refresh server list.
    final servers = await _repository.getAll();

    state = state.copyWith(
      status: ConnectionStatus.connected,
      activeServer: config,
      servers: servers,
      isBusy: false,
    );

    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: ConnectionNotifier.connect — success: id=${config.id} ===');
    }
    return true;
  }

  /// Select an existing server as active.
  Future<void> selectServer(String serverId) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: ConnectionNotifier.selectServer — id=$serverId ===');
    }

    state = state.copyWith(isBusy: true, errorMessage: null, clearError: true);

    final config = await _repository.getById(serverId);
    if (config == null) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: 'Server configuration not found.',
        isBusy: false,
      );
      return;
    }

    // Set as active.
    await _repository.setActive(serverId);

    state = state.copyWith(
      status: ConnectionStatus.connected,
      activeServer: config,
      isBusy: false,
    );
  }

  /// Soft-delete a server config.
  Future<void> deleteServer(String serverId) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: ConnectionNotifier.deleteServer — id=$serverId ===');
    }

    state = state.copyWith(isBusy: true);

    await _repository.softDelete(serverId);

    // Refresh server list.
    final servers = await _repository.getAll();

    // If we deleted the active server, clear it.
    final activeId = state.activeServer?.id;
    final newActive = (activeId == serverId) ? null : state.activeServer;

    state = state.copyWith(
      servers: servers,
      activeServer: newActive,
      clearActiveServer: activeId == serverId,
      status: newActive != null
          ? ConnectionStatus.connected
          : ConnectionStatus.idle,
      isBusy: false,
    );
  }

  /// Disconnect from the active server.
  Future<void> disconnect() async {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: ConnectionNotifier.disconnect ===');
    }

    // Clear the active server ID from storage.
    final repo = _repository;
    await repo.setActive('');

    final servers = await _repository.getAll();

    state = state.copyWith(
      status: ConnectionStatus.idle,
      activeServer: null,
      clearActiveServer: true,
      servers: servers,
      errorMessage: null,
      clearError: true,
    );
  }

  /// Clear the current error state back to idle.
  void clearError() {
    state = state.copyWith(
      status: ConnectionStatus.idle,
      errorMessage: null,
      clearError: true,
    );
  }

  /// Detect if a URL looks like a local network address.
  /// Pure function — no repository state needed.
  bool detectLocalNetwork(String url) {
    return ServerRepository.isLocalNetwork(url);
  }

  // ─── Helpers ───

  /// Generate a human-readable display name from a URL.
  String _urlToDisplayName(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final host = uri.host;
    final port = uri.port;

    if (host == 'localhost') {
      return port == 8642 || port == 0 ? 'Local Hermes' : 'localhost:$port';
    }

    // For IP addresses, include port unless it's 8642 (Hermes default).
    if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host)) {
      return (port == 8642 || port == 0) ? host : '$host:$port';
    }

    return host;
  }
}

// ─── Riverpod Provider ───

/// Provider for the connection state notifier.
/// NOT autoDispose — this is a shared, long-lived controller (DEC-034 rule 2).
final connectionProvider =
    NotifierProvider<ConnectionNotifier, ServerConnectionState>(
  ConnectionNotifier.new,
);
