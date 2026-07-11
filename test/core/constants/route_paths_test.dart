import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/core/constants/route_paths.dart';

void main() {
  group('RoutePaths.chatWithSession', () {
    test('builds path with session ID only', () {
      final path = RoutePaths.chatWithSession(id: 'abc-123');
      expect(path, '/chat?session=abc-123');
    });

    test('builds path with session ID and title', () {
      final path = RoutePaths.chatWithSession(
        id: 'abc-123',
        title: 'My Chat',
      );
      expect(path, '/chat?session=abc-123&title=My%20Chat');
    });

    test('builds path with session ID and model name', () {
      final path = RoutePaths.chatWithSession(
        id: 'abc-123',
        modelName: 'hermes-pro',
      );
      expect(path, '/chat?session=abc-123&model=hermes-pro');
    });

    test('builds full path with all parameters', () {
      final path = RoutePaths.chatWithSession(
        id: 'abc-123',
        title: 'Test Session',
        modelName: 'gpt-4',
      );
      expect(path, '/chat?session=abc-123&title=Test%20Session&model=gpt-4');
    });

    test('skips empty title', () {
      final path = RoutePaths.chatWithSession(
        id: 'abc-123',
        title: '',
        modelName: 'hermes-pro',
      );
      expect(path, '/chat?session=abc-123&model=hermes-pro');
    });

    test('skips empty modelName', () {
      final path = RoutePaths.chatWithSession(
        id: 'abc-123',
        title: 'Chat',
        modelName: '',
      );
      expect(path, '/chat?session=abc-123&title=Chat');
    });

    test('title with special characters is URL-encoded', () {
      final path = RoutePaths.chatWithSession(
        id: 'abc-123',
        title: 'Chat and More',
      );
      expect(path, '/chat?session=abc-123&title=Chat%20and%20More');
    });
  });
}
