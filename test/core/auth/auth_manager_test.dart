import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/core/auth/auth_manager.dart';
import 'package:hermex_android/core/storage/secure_storage.dart';
import 'package:hermex_android/models/server_config.dart';

/// Fake SecureStorage for testing AuthManager.
class FakeAuthStorage extends SecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> readServerConfigsRaw() async => _store['server_configs'];

  @override
  Future<void> writeServerConfigsRaw(String json) async {
    _store['server_configs'] = json;
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

void main() {
  late FakeAuthStorage fakeStorage;
  late AuthManager authManager;

  setUp(() {
    fakeStorage = FakeAuthStorage();
    authManager = AuthManager(secureStorage: fakeStorage);
  });

  group('AuthManager — active server', () {
    test('getActiveServerId returns null when none set', () async {
      final id = await authManager.getActiveServerId();
      expect(id, isNull);
    });

    test('setActiveServerId and getActiveServerId roundtrip', () async {
      await authManager.setActiveServerId('server-1');
      final id = await authManager.getActiveServerId();
      expect(id, 'server-1');
    });
  });

  group('AuthManager — API key', () {
    test('saveApiKey and getApiKeyFor roundtrip', () async {
      await authManager.saveApiKey('server-1', 'secret-key');
      final key = await authManager.getApiKeyFor('server-1');
      expect(key, 'secret-key');
    });

    test('getApiKey returns null when no active server', () async {
      final key = await authManager.getApiKey();
      expect(key, isNull);
    });

    test('getApiKey returns key for active server', () async {
      await authManager.saveApiKey('server-1', 'secret-key');
      await authManager.setActiveServerId('server-1');

      final key = await authManager.getApiKey();
      expect(key, 'secret-key');
    });

    test('deleteApiKey removes the key', () async {
      await authManager.saveApiKey('server-1', 'secret-key');
      await authManager.deleteApiKey('server-1');

      final key = await authManager.getApiKeyFor('server-1');
      expect(key, isNull);
    });

    test('hasApiKey returns false when no key', () async {
      final hasKey = await authManager.hasApiKey();
      expect(hasKey, false);
    });

    test('hasApiKey returns true when key exists', () async {
      await authManager.saveApiKey('server-1', 'secret-key');
      await authManager.setActiveServerId('server-1');

      final hasKey = await authManager.hasApiKey();
      expect(hasKey, true);
    });
  });

  group('AuthManager — server URL', () {
    test('getActiveServerUrl returns null when no configs', () async {
      await authManager.setActiveServerId('server-1');
      final url = await authManager.getActiveServerUrl();
      expect(url, isNull);
    });

    test('getActiveServerUrl returns URL from config', () async {
      final config = ServerConfig(
        id: 'server-1',
        name: 'Test',
        url: 'http://192.168.1.100:8642',
        isDefault: true,
        createdAt: DateTime.now(),
      );

      // Save config to fake storage
      await fakeStorage.writeServerConfigsRaw(
        jsonEncode([config.toJson()]),
      );
      await authManager.setActiveServerId('server-1');

      final url = await authManager.getActiveServerUrl();
      expect(url, 'http://192.168.1.100:8642');
    });

    test('getActiveServerUrl returns null for deleted config', () async {
      final config = ServerConfig(
        id: 'server-1',
        name: 'Test',
        url: 'http://192.168.1.100:8642',
        isDefault: true,
        createdAt: DateTime.now(),
        isDeleted: true,
      );

      await fakeStorage.writeServerConfigsRaw(
        jsonEncode([config.toJson()]),
      );
      await authManager.setActiveServerId('server-1');

      final url = await authManager.getActiveServerUrl();
      expect(url, isNull);
    });
  });

  group('AuthManager — auth header', () {
    test('getAuthHeader returns null when no active server', () async {
      final header = await authManager.getAuthHeader();
      expect(header, isNull);
    });

    test('getAuthHeader returns Bearer token', () async {
      await authManager.saveApiKey('server-1', 'secret-key');
      await authManager.setActiveServerId('server-1');

      final header = await authManager.getAuthHeader();
      expect(header, 'Bearer secret-key');
    });
  });

  group('AuthManager — clearAll', () {
    test('clearAll removes all data', () async {
      await authManager.saveApiKey('server-1', 'secret-key');
      await authManager.setActiveServerId('server-1');

      await authManager.clearAll();

      final key = await authManager.getApiKey();
      final id = await authManager.getActiveServerId();

      expect(key, isNull);
      expect(id, isNull);
    });
  });

  group('AuthManager — active server config', () {
    test('getActiveServerConfig returns config object', () async {
      final config = ServerConfig(
        id: 'server-1',
        name: 'Test Server',
        url: 'http://192.168.1.100:8642',
        isDefault: true,
        createdAt: DateTime.now(),
      );

      await fakeStorage.writeServerConfigsRaw(
        jsonEncode([config.toJson()]),
      );
      await authManager.setActiveServerId('server-1');

      final result = await authManager.getActiveServerConfig();
      expect(result, isNotNull);
      expect(result!.id, 'server-1');
      expect(result.name, 'Test Server');
      expect(result.url, 'http://192.168.1.100:8642');
    });
  });
}
