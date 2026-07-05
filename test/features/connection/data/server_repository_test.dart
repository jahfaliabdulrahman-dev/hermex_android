import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/connection/data/server_repository.dart';
import 'package:hermex_android/core/storage/secure_storage.dart';

void main() {
  late ServerRepository repository;

  setUp(() {
    repository = ServerRepository(secureStorage: SecureStorage());
  });

  group('URL validation', () {
    test('rejects empty URL', () async {
      final result = await repository.healthCheck(
        url: '',
        apiKey: 'test-key',
      );

      expect(result.isSuccess, false);
      expect(result.failure, HealthCheckFailure.invalidUrl);
    });

    test('rejects URL without scheme', () async {
      final result = await repository.healthCheck(
        url: '192.168.1.100:8642',
        apiKey: 'test-key',
      );

      expect(result.isSuccess, false);
      expect(result.failure, HealthCheckFailure.invalidUrl);
    });

    test('accepts URL with http:// scheme', () async {
      // This would fail on connection, but validation passes.
      // We test that invalidUrl is NOT the failure mode.
      final result = await repository.healthCheck(
        url: 'http://192.168.1.100:8642',
        apiKey: 'test-key',
      );

      // Should NOT be invalidUrl (it will fail with unreachable/timeout instead)
      expect(result.failure, isNot(HealthCheckFailure.invalidUrl));
    });

    test('accepts URL with https:// scheme', () async {
      final result = await repository.healthCheck(
        url: 'https://api.example.com:8642',
        apiKey: 'test-key-123456',
      );

      expect(result.failure, isNot(HealthCheckFailure.invalidUrl));
    });

    test('rejects HTTP scheme on remote (non-RFC 1918) host', () async {
      // HTTP should NOT be allowed on a public IP / remote host.
      final result = await repository.healthCheck(
        url: 'http://api.example.com:8642',
        apiKey: 'test-key-123456',
      );

      expect(result.isSuccess, false);
      expect(result.failure, HealthCheckFailure.invalidUrl);
      expect(result.message, contains('HTTP'));
    });

    test('rejects URL with userinfo (host injection via @)', () async {
      // http://evil.com@192.168.1.100:8642 should be rejected because
      // evil.com becomes the userInfo component — host injection attack.
      final result = await repository.healthCheck(
        url: 'http://evil.com@192.168.1.100:8642',
        apiKey: 'test-key-123456',
      );

      expect(result.isSuccess, false);
      expect(result.failure, HealthCheckFailure.invalidUrl);
      expect(result.message, contains('credentials'));
    });

    test('rejects URL with userinfo in https:// URL too', () async {
      final result = await repository.healthCheck(
        url: 'https://user:pass@api.example.com:8642',
        apiKey: 'test-key-123456',
      );

      expect(result.isSuccess, false);
      expect(result.failure, HealthCheckFailure.invalidUrl);
      expect(result.message, contains('credentials'));
    });
  });

  group('local network detection', () {
    test('detects localhost', () {
      expect(ServerRepository.isLocalNetwork('http://localhost:8642'), true);
      expect(ServerRepository.isLocalNetwork('http://localhost'), true);
    });

    test('detects 127.0.0.1', () {
      expect(ServerRepository.isLocalNetwork('http://127.0.0.1:8642'), true);
    });

    test('detects 192.168.x.x', () {
      expect(ServerRepository.isLocalNetwork('http://192.168.1.100:8642'), true);
      expect(ServerRepository.isLocalNetwork('http://192.168.0.1'), true);
    });

    test('detects 10.x.x.x', () {
      expect(ServerRepository.isLocalNetwork('http://10.0.0.1:8642'), true);
      expect(ServerRepository.isLocalNetwork('http://10.10.10.10'), true);
    });

    test('detects 172.16-31.x.x', () {
      expect(ServerRepository.isLocalNetwork('http://172.16.0.1:8642'), true);
      expect(ServerRepository.isLocalNetwork('http://172.31.255.255'), true);
    });

    test('rejects 172.32.x.x (non-private)', () {
      expect(ServerRepository.isLocalNetwork('http://172.32.0.1:8642'), false);
    });

    test('rejects public IPs', () {
      expect(ServerRepository.isLocalNetwork('https://api.example.com'), false);
      expect(ServerRepository.isLocalNetwork('http://8.8.8.8'), false);
    });

    test('handles URL with trailing slash', () {
      expect(ServerRepository.isLocalNetwork('http://192.168.1.100:8642/'), true);
    });
  });

  group('HealthCheckResult', () {
    test('success result has isSuccess=true', () {
      final result = HealthCheckResult.success();
      expect(result.isSuccess, true);
      expect(result.failure, isNull);
      expect(result.message, isNull);
    });

    test('failure result has isSuccess=false and message', () {
      final result = HealthCheckResult.failure(
        HealthCheckFailure.timeout,
        message: 'Custom timeout message',
      );
      expect(result.isSuccess, false);
      expect(result.failure, HealthCheckFailure.timeout);
      expect(result.message, 'Custom timeout message');
    });

    test('failure result uses default message when none provided', () {
      final result = HealthCheckResult.failure(HealthCheckFailure.authFailed);
      expect(result.message, HealthCheckFailure.authFailed.defaultMessage);
    });
  });

  group('HealthCheckFailure enum', () {
    test('each failure has a default message', () {
      for (final failure in HealthCheckFailure.values) {
        expect(failure.defaultMessage, isNotEmpty);
      }
    });
  });
}
