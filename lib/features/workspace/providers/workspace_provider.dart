import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../models/workspace_entry.dart';
import '../data/workspace_repository.dart';

/// Provider for the WorkspaceRepository (DI via apiClientProvider).
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkspaceRepository(apiClient: apiClient);
});

/// Fetch directory contents for a given path.
/// FutureProvider.family: each path gets its own cached provider.
final directoryContentsProvider =
    FutureProvider.family<List<WorkspaceEntry>, String>((ref, path) {
  final repository = ref.watch(workspaceRepositoryProvider);
  return repository.getDirectoryContents(path);
});

/// Fetch file content for a given path.
/// FutureProvider.family: each path gets its own cached provider.
final fileContentProvider =
    FutureProvider.family<String, String>((ref, path) {
  final repository = ref.watch(workspaceRepositoryProvider);
  return repository.getFileContent(path);
});

/// UI state for workspace navigation.
class WorkspaceBrowserState {
  /// The current directory path being browsed.
  final String currentPath;

  /// Breadcrumb trail segments.
  final List<String> pathSegments;

  /// The currently selected file path for preview, or null.
  final String? selectedFilePath;

  const WorkspaceBrowserState({
    this.currentPath = '',
    this.pathSegments = const [],
    this.selectedFilePath,
  });

  WorkspaceBrowserState copyWith({
    String? currentPath,
    List<String>? pathSegments,
    String? selectedFilePath,
    bool clearSelectedFile = false,
  }) {
    return WorkspaceBrowserState(
      currentPath: currentPath ?? this.currentPath,
      pathSegments: pathSegments ?? this.pathSegments,
      selectedFilePath:
          clearSelectedFile ? null : (selectedFilePath ?? this.selectedFilePath),
    );
  }
}

/// Notifier for workspace browser navigation state.
class WorkspaceBrowserNotifier extends Notifier<WorkspaceBrowserState> {
  @override
  WorkspaceBrowserState build() {
    return const WorkspaceBrowserState();
  }

  /// Navigate into a subdirectory.
  void navigateInto(String folderName) {
    final newPath = state.currentPath.isEmpty
        ? folderName
        : '${state.currentPath}/$folderName';
    final segments = _pathToSegments(newPath);

    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: WorkspaceBrowserNotifier.navigateInto — $newPath ===');
    }

    state = state.copyWith(
      currentPath: newPath,
      pathSegments: segments,
      selectedFilePath: null,
      clearSelectedFile: true,
    );
  }

  /// Navigate back to the parent directory.
  void navigateUp() {
    if (state.pathSegments.isEmpty) return;

    final segments = List<String>.from(state.pathSegments)..removeLast();
    final newPath = segments.join('/');

    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: WorkspaceBrowserNotifier.navigateUp — $newPath ===');
    }

    state = state.copyWith(
      currentPath: newPath,
      pathSegments: segments,
      selectedFilePath: null,
      clearSelectedFile: true,
    );
  }

  /// Navigate to a specific breadcrumb segment.
  void navigateToSegment(int index) {
    List<String> segments;
    if (index < 0) {
      segments = [];
    } else {
      segments = state.pathSegments.sublist(0, index + 1);
    }
    final newPath = segments.join('/');

    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: WorkspaceBrowserNotifier.navigateToSegment — $newPath ===');
    }

    state = state.copyWith(
      currentPath: newPath,
      pathSegments: segments,
      selectedFilePath: null,
      clearSelectedFile: true,
    );
  }

  /// Select a file for content preview.
  void selectFile(String filePath) {
    final fullPath = state.currentPath.isEmpty
        ? filePath
        : '${state.currentPath}/$filePath';

    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: WorkspaceBrowserNotifier.selectFile — $fullPath ===');
    }

    state = state.copyWith(selectedFilePath: fullPath);
  }

  /// Clear the file preview.
  void clearSelection() {
    state = state.copyWith(
      selectedFilePath: null,
      clearSelectedFile: true,
    );
  }

  /// Refresh current directory.
  void refresh() {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: WorkspaceBrowserNotifier.refresh — ${state.currentPath} ===');
    }
    // The widget watching directoryContentsProvider will trigger a fresh fetch.
  }

  /// Convert a path string to breadcrumb segments.
  List<String> _pathToSegments(String path) {
    if (path.isEmpty) return [];
    return path.split('/').where((s) => s.isNotEmpty).toList();
  }
}

/// Provider for workspace browser navigation state.
/// NOT autoDispose — shared controller across workspace screens.
final workspaceBrowserProvider =
    NotifierProvider<WorkspaceBrowserNotifier, WorkspaceBrowserState>(
  WorkspaceBrowserNotifier.new,
);
