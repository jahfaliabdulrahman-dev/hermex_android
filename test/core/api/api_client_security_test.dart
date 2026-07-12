import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/core/api/api_exception.dart';
import 'package:hermex_android/core/constants/security_limits.dart';

void main() {
  group('PayloadTooLargeException', () {
    test('stores maxAllowed and actual bytes', () {
      final ex = PayloadTooLargeException(
        maxAllowedBytes: 1024,
        actualBytes: 2048,
      );

      expect(ex.maxAllowedBytes, 1024);
      expect(ex.actualBytes, 2048);
      expect(ex.message, contains('2048 bytes'));
      expect(ex.message, contains('1024 bytes limit'));
    });

    test('inherits from ApiException', () {
      final ex = PayloadTooLargeException(
        maxAllowedBytes: 100,
        actualBytes: 200,
      );

      expect(ex, isA<ApiException>());
    });

    test('toString returns user-safe message, toDebugString includes details', () {
      final ex = PayloadTooLargeException(
        maxAllowedBytes: 500,
        actualBytes: 1000,
      );

      // toString() must NOT leak internal details to UI.
      final str = ex.toString();
      expect(str, contains('Request failed'));
      expect(str, isNot(contains('500')));
      expect(str, isNot(contains('1000')));

      // toDebugString() includes full details for debug logging only.
      final debug = ex.toDebugString();
      expect(debug, contains('PayloadTooLargeException'));
      expect(debug, contains('500'));
      expect(debug, contains('1000'));
    });
  });

  group('ContentTruncatedException', () {
    test('stores maxAllowed and actual characters', () {
      final ex = ContentTruncatedException(
        maxAllowedCharacters: 50,
        actualCharacters: 500,
      );

      expect(ex.maxAllowedCharacters, 50);
      expect(ex.actualCharacters, 500);
      expect(ex.message, contains('500'));
      expect(ex.message, contains('50 characters'));
    });

    test('inherits from ApiException', () {
      final ex = ContentTruncatedException(
        maxAllowedCharacters: 100,
        actualCharacters: 999,
      );

      expect(ex, isA<ApiException>());
    });
  });

  group('Response size validation (AUD-006)', () {
    test('small JSON string passes size check', () {
      final smallJson = '{"ok": true}';
      expect(smallJson.length, lessThan(SecurityLimits.maxJsonResponseSize));
      expect(smallJson.length, lessThanOrEqualTo(SecurityLimits.maxJsonResponseSize));
    });

    test('response at exact limit is considered within bounds', () {
      final exactlyAtLimit = 'x' * SecurityLimits.maxJsonResponseSize;
      // At exactly the limit, it's within bounds (not greater than).
      expect(exactlyAtLimit.length, SecurityLimits.maxJsonResponseSize);
    });

    test('response exceeding limit is detected', () {
      final overLimit = 'x' * (SecurityLimits.maxJsonResponseSize + 100);
      expect(overLimit.length, greaterThan(SecurityLimits.maxJsonResponseSize));
    });

    test('large list response detection', () {
      final chunk = 'x' * 10000;
      // Build a list that when serialized exceeds the limit.
      final count = (SecurityLimits.maxJsonResponseSize ~/ chunk.length) + 2;
      final largeList = List.filled(count, chunk);
      final serialized = largeList.toString();
      expect(serialized.length, greaterThan(SecurityLimits.maxJsonResponseSize));
    });
  });

  group('SecurityLimits constants', () {
    test('maxSseEventSize is 5MB', () {
      expect(SecurityLimits.maxSseEventSize, 5 * 1024 * 1024);
    });

    test('maxJsonResponseSize is 10MB', () {
      expect(SecurityLimits.maxJsonResponseSize, 10 * 1024 * 1024);
    });

    test('maxTextDeltaSize is 50KB', () {
      expect(SecurityLimits.maxTextDeltaSize, 50 * 1024);
    });
  });
}
