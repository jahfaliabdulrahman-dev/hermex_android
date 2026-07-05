import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/models/memory_entry.dart';

void main() {
  group('MemoryEntry — fromJson', () {
    test('parses a complete memory entry', () {
      final json = {
        'id': 'mem-1',
        'title': 'User prefers dark mode',
        'description': 'The user has expressed a preference for dark mode.',
        'created_at': '2026-07-05T10:00:00Z',
        'updated_at': '2026-07-05T12:00:00Z',
      };

      final entry = MemoryEntry.fromJson(json);

      expect(entry.id, 'mem-1');
      expect(entry.title, 'User prefers dark mode');
      expect(entry.description, 'The user has expressed a preference for dark mode.');
      expect(entry.createdAt, DateTime.parse('2026-07-05T10:00:00Z'));
      expect(entry.updatedAt, DateTime.parse('2026-07-05T12:00:00Z'));
    });

    test('falls back to "key" field for id', () {
      final json = {
        'key': 'mem-key',
        'title': 'Test',
      };

      final entry = MemoryEntry.fromJson(json);

      expect(entry.id, 'mem-key');
    });

    test('falls back to "key" for title', () {
      final json = {
        'id': 'mem-1',
        'key': 'User location',
      };

      final entry = MemoryEntry.fromJson(json);

      expect(entry.title, 'User location');
    });

    test('defaults title to "Untitled" when missing', () {
      final json = {
        'id': 'mem-1',
      };

      final entry = MemoryEntry.fromJson(json);

      expect(entry.title, 'Untitled');
    });

    test('handles null created_at and updated_at', () {
      final json = {
        'id': 'mem-1',
        'title': 'Test',
      };

      final entry = MemoryEntry.fromJson(json);

      expect(entry.createdAt, isNull);
      expect(entry.updatedAt, isNull);
    });

    test('handles malformed date gracefully', () {
      final json = {
        'id': 'mem-1',
        'title': 'Test',
        'created_at': 'not-a-date',
      };

      final entry = MemoryEntry.fromJson(json);

      expect(entry.createdAt, isNull);
    });

    test('handles empty JSON gracefully', () {
      final entry = MemoryEntry.fromJson({});

      expect(entry.id, '');
      expect(entry.title, 'Untitled');
      expect(entry.description, isNull);
    });
  });

  group('MemoryEntry — parseList', () {
    test('parses a direct list', () {
      final body = [
        {'id': '1', 'title': 'Memory 1'},
        {'id': '2', 'title': 'Memory 2'},
      ];

      final entries = MemoryEntry.parseList(body);

      expect(entries.length, 2);
      expect(entries[0].title, 'Memory 1');
    });

    test('parses a wrapped response with "memories" key', () {
      final body = {
        'memories': [
          {'id': '1', 'title': 'Memory 1'},
        ],
      };

      final entries = MemoryEntry.parseList(body);

      expect(entries.length, 1);
    });

    test('parses a wrapped response with "data" key', () {
      final body = {
        'data': [
          {'id': '1', 'title': 'Memory 1'},
        ],
      };

      final entries = MemoryEntry.parseList(body);

      expect(entries.length, 1);
    });

    test('returns empty list for null', () {
      expect(MemoryEntry.parseList(null), isEmpty);
    });

    test('returns empty list for empty map', () {
      expect(MemoryEntry.parseList({}), isEmpty);
    });
  });

  group('MemoryEntry — equality', () {
    test('two entries with same id are equal', () {
      final a = MemoryEntry(id: '1', title: 'A');
      final b = MemoryEntry(id: '1', title: 'B');

      expect(a, equals(b));
    });

    test('two entries with different id are not equal', () {
      final a = MemoryEntry(id: '1', title: 'A');
      final b = MemoryEntry(id: '2', title: 'A');

      expect(a, isNot(equals(b)));
    });
  });
}
