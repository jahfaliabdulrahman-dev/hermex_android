import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hermex_android/features/connection/providers/connection_provider.dart';
import 'package:hermex_android/core/storage/secure_storage.dart';
import 'package:hermex_android/models/server_config.dart';

/// Fake SecureStorage that stores data in memory for testing.
class FakeSecureStorage extends SecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> readServerConfigsRaw() async => _store['server_configs'];

  @override
  Future<void> writeServerConfigsRaw(String json) async {
    _store['server_configs'] = json;
  }

  @override
  Future<void> deleteServerConfigs() async {
    _store.remove('server_configs');
  }

  @override
  Future<String?> readActiveServerId() async => _store['active_server_id'];

  @override
  Future<void> writeActiveServerId(String serverId) async {
    _store['active_server_id'] = serverId;
  }

  @override
  Future<String?> readApiKey(String serverId) async =>
      _store['api_key_$serverId'];

  @override
  Future<void> writeApiKey(String serverId, String apiKey) async {
    _store['api_key_$serverId'] = apiKey;
  }

  @override
  Future<void> deleteApiKey(String serverId) async {
    _store.remove('api_key_$serverId');
  }

  @override
  Future<void> deleteAll() async {
    _store.clear();
  }
}

/// Testable ConnectionNotifier that uses FakeSecureStorage.
class TestConnectionNotifier extends ConnectionNotifier {
  final FakeSecureStorage fakeStorage;

  TestConnectionNotifier(this.fakeStorage);

  @override
  ServerConnectionState build() {
    return const ServerConnectionState();
  }
}

void main() {
  group('ServerConnectionState — copyWith', () {
    test('updates status', () {
      final state = const ServerConnectionState();
      final updated = state.copyWith(status: ConnectionStatus.connecting);

      expect(updated.status, ConnectionStatus.connecting);
      expect(state.status, ConnectionStatus.idle); // Original unchanged
    });

    test('clearActiveServer sets active to null', () {
      final state = ServerConnectionState(
        activeServer: ServerConfig(
          id: 'test',
          name: 'test',
          url: 'http://test',
          createdAt: DateTime.now(),
        ),
      );
      final updated = state.copyWith(clearActiveServer: true);

      expect(updated.activeServer, isNull);
    });

    test('clearError removes error message', () {
      final state = const ServerConnectionState(errorMessage: 'Error!');
      final updated = state.copyWith(clearError: true);

      expect(updated.errorMessage, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      final original = ServerConnectionState(
        status: ConnectionStatus.connected,
        servers: [],
        isLocalNetwork: true,
        errorMessage: 'test',
      );
      final updated = original.copyWith(status: ConnectionStatus.idle);

      expect(updated.servers, original.servers);
      expect(updated.isLocalNetwork, original.isLocalNetwork);
      expect(updated.errorMessage, original.errorMessage);
    });
  });

  group('ServerConnectionState — default values', () {
    test('default is idle with empty servers', () {
      const state = ServerConnectionState();

      expect(state.status, ConnectionStatus.idle);
      expect(state.activeServer, isNull);
      expect(state.servers, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.isBusy, false);
      expect(state.isLocalNetwork, false);
    });
  });

  group('ConnectionNotifier — local network detection', () {
    test('detects local network URLs', () {
      // Use ProviderContainer with overridden storage to test notifier
      final container = ProviderContainer(
        overrides: [
          connectionProvider.overrideWith(
            () => TestConnectionNotifier(FakeSecureStorage()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(connectionProvider.notifier);

      expect(notifier.detectLocalNetwork('https://api.example.com'), false);
      expect(notifier.detectLocalNetwork('http://192.168.1.100:8642'), true);
      expect(notifier.detectLocalNetwork('http://localhost:8642'), true);
      expect(notifier.detectLocalNetwork('http://10.0.0.1:8642'), true);
      expect(notifier.detectLocalNetwork('http://172.16.0.1:8642'), true);
    });
  });

  group('ConnectionNotifier — state management', () {
    test('clearError resets to idle', () {
      final container = ProviderContainer(
        overrides: [
          connectionProvider.overrideWith(
            () => TestConnectionNotifier(FakeSecureStorage()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(connectionProvider.notifier);
      notifier.clearError();

      final state = container.read(connectionProvider);
      expect(state.status, ConnectionStatus.idle);
      expect(state.errorMessage, isNull);
    });
  });
}
