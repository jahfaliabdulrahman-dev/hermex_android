import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/models/session_summary.dart';

void main() {
  group('SessionSummary — fromJson', () {
    test('parses a complete session summary', () {
      final json = {
        'id': 'sess-123',
        'title': 'API Design Discussion',
        'model_name': 'deepseek-v4-pro',
        'message_count': 42,
        'created_at': 1700000000,
        'last_activity': 1700100000,
        'is_pinned': true,
        'is_archived': false,
        'status': 'active',
      };

      final session = SessionSummary.fromJson(json);

      expect(session.id, 'sess-123');
      expect(session.title, 'API Design Discussion');
      expect(session.modelName, 'deepseek-v4-pro');
      expect(session.messageCount, 42);
      expect(session.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000));
      expect(session.lastActivity, DateTime.fromMillisecondsSinceEpoch(1700100000 * 1000));
      expect(session.isPinned, true);
      expect(session.isArchived, false);
      expect(session.status, 'active');
    });

    test('parses string timestamps', () {
      final json = {
        'id': 'sess-1',
        'created_at': '2026-07-05T10:00:00Z',
        'last_activity': '2026-07-05T12:00:00Z',
      };

      final session = SessionSummary.fromJson(json);

      expect(session.createdAt, DateTime.parse('2026-07-05T10:00:00Z'));
      expect(session.lastActivity, DateTime.parse('2026-07-05T12:00:00Z'));
    });

    test('defaults missing fields', () {
      final json = {
        'id': 'sess-1',
      };

      final session = SessionSummary.fromJson(json);

      expect(session.title, isNull);
      expect(session.messageCount, 0);
      expect(session.isPinned, false);
      expect(session.isArchived, false);
      expect(session.createdAt, isNull);
    });

    test('handles null timestamps', () {
      final json = {
        'id': 'sess-1',
        'created_at': null,
        'last_activity': null,
      };

      final session = SessionSummary.fromJson(json);

      expect(session.createdAt, isNull);
      expect(session.lastActivity, isNull);
    });

    test('handles malformed date gracefully', () {
      final json = {
        'id': 'sess-1',
        'created_at': 'not-a-date',
      };

      final session = SessionSummary.fromJson(json);

      expect(session.createdAt, isNull);
    });
  });

  group('SessionSummary — equality', () {
    test('two sessions with same fields are equal', () {
      final a = SessionSummary(id: 'sess-1', title: 'Test');
      final b = SessionSummary(id: 'sess-1', title: 'Test');
      expect(a, equals(b));
    });

    test('two sessions with different id are not equal', () {
      final a = SessionSummary(id: 'sess-1');
      final b = SessionSummary(id: 'sess-2');
      expect(a, isNot(equals(b)));
    });
  });
}
