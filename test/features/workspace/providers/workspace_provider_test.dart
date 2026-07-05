import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/workspace/providers/workspace_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkspaceBrowserState', () {
    test('initial state is at root', () {
      const state = WorkspaceBrowserState();

      expect(state.currentPath, '');
      expect(state.pathSegments, isEmpty);
      expect(state.selectedFilePath, isNull);
    });

    test('copyWith updates currentPath', () {
      const state = WorkspaceBrowserState();
      final updated = state.copyWith(currentPath: '/home');

      expect(updated.currentPath, '/home');
      expect(updated.pathSegments, isEmpty);
    });

    test('copyWith updates pathSegments', () {
      const state = WorkspaceBrowserState();
      final updated = state.copyWith(pathSegments: ['home', 'user']);

      expect(updated.pathSegments, ['home', 'user']);
    });

    test('copyWith clearSelectedFile removes selection', () {
      final state = WorkspaceBrowserState(
        selectedFilePath: 'some/file.txt',
      );

      final cleared = state.copyWith(clearSelectedFile: true);

      expect(cleared.selectedFilePath, isNull);
    });
  });

  group('WorkspaceBrowserNotifier', () {
    test('initial state is at root with no selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(workspaceBrowserProvider);
      expect(state.currentPath, '');
      expect(state.pathSegments, isEmpty);
      expect(state.selectedFilePath, isNull);
    });

    test('navigateInto updates path and segments', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceBrowserProvider.notifier);
      notifier.navigateInto('documents');

      final state = container.read(workspaceBrowserProvider);
      expect(state.currentPath, 'documents');
      expect(state.pathSegments, ['documents']);
    });

    test('navigateInto builds nested path from subdirectories', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceBrowserProvider.notifier);
      notifier.navigateInto('home');
      notifier.navigateInto('user');
      notifier.navigateInto('projects');

      final state = container.read(workspaceBrowserProvider);
      expect(state.currentPath, 'home/user/projects');
      expect(state.pathSegments, ['home', 'user', 'projects']);
    });

    test('navigateUp goes to parent directory', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceBrowserProvider.notifier);
      notifier.navigateInto('home');
      notifier.navigateInto('user');
      notifier.navigateUp();

      final state = container.read(workspaceBrowserProvider);
      expect(state.currentPath, 'home');
      expect(state.pathSegments, ['home']);
    });

    test('navigateUp at root does nothing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceBrowserProvider.notifier);
      notifier.navigateUp();

      final state = container.read(workspaceBrowserProvider);
      expect(state.currentPath, '');
      expect(state.pathSegments, isEmpty);
    });

    test('navigateToSegment goes to a specific breadcrumb index', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceBrowserProvider.notifier);
      notifier.navigateInto('home');
      notifier.navigateInto('user');
      notifier.navigateInto('docs');
      notifier.navigateToSegment(1);

      final state = container.read(workspaceBrowserProvider);
      expect(state.currentPath, 'home/user');
      expect(state.pathSegments, ['home', 'user']);
    });

    test('navigateToSegment with -1 goes to root', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceBrowserProvider.notifier);
      notifier.navigateInto('a');
      notifier.navigateInto('b');
      notifier.navigateToSegment(-1);

      final state = container.read(workspaceBrowserProvider);
      expect(state.currentPath, '');
      expect(state.pathSegments, isEmpty);
    });

    test('selectFile sets selectedFilePath', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceBrowserProvider.notifier);
      notifier.selectFile('readme.txt');

      final state = container.read(workspaceBrowserProvider);
      expect(state.selectedFilePath, 'readme.txt');
    });

    test('selectFile constructs full path from current directory', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceBrowserProvider.notifier);
      notifier.navigateInto('docs');
      notifier.selectFile('api.md');

      final state = container.read(workspaceBrowserProvider);
      expect(state.selectedFilePath, 'docs/api.md');
    });

    test('clearSelection removes file preview', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceBrowserProvider.notifier);
      notifier.selectFile('file.txt');
      notifier.clearSelection();

      final state = container.read(workspaceBrowserProvider);
      expect(state.selectedFilePath, isNull);
    });

    test('navigateInto clears file selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceBrowserProvider.notifier);
      notifier.selectFile('file.txt');
      notifier.navigateInto('subdir');

      final state = container.read(workspaceBrowserProvider);
      expect(state.selectedFilePath, isNull);
      expect(state.currentPath, 'subdir');
    });
  });
}
