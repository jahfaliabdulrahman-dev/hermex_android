import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/workspace/data/workspace_repository.dart';
import 'package:hermex_android/models/workspace_entry.dart';

void main() {
  late WorkspaceRepository repository;

  setUp(() {
    repository = WorkspaceRepository(apiClient: null);
  });

  group('WorkspaceRepository — no client', () {
    test('getDirectoryContents returns empty list when no apiClient', () async {
      final entries = await repository.getDirectoryContents('');
      expect(entries, isEmpty);
    });

    test('getDirectoryContents returns empty list for any path with no client',
        () async {
      final entries = await repository.getDirectoryContents('/some/path');
      expect(entries, isEmpty);
    });

    test('getFileContent throws when no apiClient', () async {
      expect(
        () => repository.getFileContent('file.txt'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('WorkspaceEntry model — parsing', () {
    test('fromJson parses a file entry', () {
      final json = {
        'name': 'README.md',
        'type': 'file',
        'size': 2048,
        'modified_at': '2026-07-05T10:00:00Z',
        'is_binary': false,
      };

      final entry = WorkspaceEntry.fromJson(json);

      expect(entry.name, 'README.md');
      expect(entry.type, 'file');
      expect(entry.size, 2048);
      expect(entry.modifiedAt, '2026-07-05T10:00:00Z');
      expect(entry.isBinary, false);
    });

    test('fromJson parses a directory entry', () {
      final json = {
        'name': 'src',
        'type': 'directory',
        'size': 0,
      };

      final entry = WorkspaceEntry.fromJson(json);

      expect(entry.name, 'src');
      expect(entry.type, 'directory');
      expect(entry.size, 0);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'name': 'unknown.file',
      };

      final entry = WorkspaceEntry.fromJson(json);

      expect(entry.name, 'unknown.file');
      expect(entry.type, 'file'); // default
      expect(entry.size, 0); // default
      expect(entry.modifiedAt, isNull);
      expect(entry.isBinary, false); // default
    });

    test('fromJson handles binary file flag', () {
      final json = {
        'name': 'image.png',
        'type': 'file',
        'is_binary': true,
      };

      final entry = WorkspaceEntry.fromJson(json);

      expect(entry.isBinary, true);
    });
  });
}
