import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../data/datasources/local/isar_provider.dart';
import '../../../models/session_summary.dart';
import '../data/session_repository.dart';

/// Provider for the SessionRepository (DI).
final sessionRepositoryProvider = Provider<SessionRepository?>((ref) {
  final apiClient = ref.watch(resolvedApiClientProvider).valueOrNull;
  if (apiClient == null) return null;

  final isar = ref.watch(isarProvider);
  return SessionRepository(apiClient: apiClient, isar: isar);
});

/// Fetch the list of sessions from the API.
/// FutureProvider: handles loading/error/data states automatically.
/// Falls back to cache if API call fails.
final sessionListProvider = FutureProvider<List<SessionSummary>>((ref) async {
  final repository = ref.watch(sessionRepositoryProvider);
  if (repository == null) {
    throw StateError('No active server — cannot fetch sessions.');
  }

  try {
    return await repository.getSessions();
  } catch (e) {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: sessionListProvider — API failed, trying cache: $e ===');
    }

    // Try cache fallback.
    final cached = await repository.getCachedSessions();
    if (cached.isNotEmpty) {
      // Convert CachedSession to SessionSummary for UI consistency.
      return cached
          .map((c) => SessionSummary(
                id: c.sessionId,
                title: c.title,
                modelName: c.modelName,
                messageCount: c.messageCount,
                lastActivity: c.lastActivity,
                isPinned: c.isPinned,
                isArchived: c.isArchived,
              ))
          .toList();
    }

    rethrow;
  }
});

/// Fetch a single session detail from the API.
final sessionDetailProvider =
    FutureProvider.family<SessionSummary, String>((ref, id) async {
  final repository = ref.watch(sessionRepositoryProvider);
  if (repository == null) {
    throw StateError('No active server — cannot fetch session.');
  }

  return repository.getSession(id);
});

// ─── UI State ───

/// Complete UI state for the sessions screen.
class SessionsScreenState {
  /// Current search query (filters by session title).
  final String searchQuery;

  /// Whether to show only archived sessions.
  final bool showArchived;

  /// Whether the app is in offline mode (showing cached data).
  final bool isOffline;

  /// Set of session IDs currently having a mutation in-flight.
  final Set<String> mutatingSessionIds;

  /// Whether a delete confirmation dialog is showing.
  final String? deleteConfirmSessionId;

  /// Whether the rename dialog is showing.
  final String? renameSessionId;

  /// Error message for toast/error display.
  final String? errorMessage;

  const SessionsScreenState({
    this.searchQuery = '',
    this.showArchived = false,
    this.isOffline = false,
    this.mutatingSessionIds = const {},
    this.deleteConfirmSessionId,
    this.renameSessionId,
    this.errorMessage,
  });

  /// Whether a specific session is currently being mutated.
  bool isMutating(String id) => mutatingSessionIds.contains(id);

  SessionsScreenState copyWith({
    String? searchQuery,
    bool? showArchived,
    bool? isOffline,
    Set<String>? mutatingSessionIds,
    String? deleteConfirmSessionId,
    bool clearDeleteConfirm = false,
    String? renameSessionId,
    bool clearRenameSession = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionsScreenState(
      searchQuery: searchQuery ?? this.searchQuery,
      showArchived: showArchived ?? this.showArchived,
      isOffline: isOffline ?? this.isOffline,
      mutatingSessionIds: mutatingSessionIds ?? this.mutatingSessionIds,
      deleteConfirmSessionId:
          clearDeleteConfirm ? null : (deleteConfirmSessionId ?? this.deleteConfirmSessionId),
      renameSessionId:
          clearRenameSession ? null : (renameSessionId ?? this.renameSessionId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier for the sessions screen UI state and CRUD operations.
///
/// Manages: search, archive filter, offline toggle, and session mutations
/// (create, rename, delete, pin, archive, fork).
///
/// NOT autoDispose — shared long-lived controller (DEC-034 rule 2).
class SessionsNotifier extends Notifier<SessionsScreenState> {
  @override
  SessionsScreenState build() {
    return const SessionsScreenState();
  }

  // ─── Search & Filter ───

  /// Update the search query. Filters are applied client-side.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Toggle showing archived sessions only.
  void toggleShowArchived() {
    state = state.copyWith(showArchived: !state.showArchived);
  }

  /// Set offline mode (called by the app shell when connectivity changes).
  void setOffline(bool offline) {
    state = state.copyWith(isOffline: offline);
  }

  /// Clear any error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ─── Mutations ───

  /// Create a new session and return its ID for navigation.
  Future<String?> createSession({String? title}) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: SessionsNotifier.createSession — title=$title ===');
    }

    if (state.isOffline) {
      state = state.copyWith(
        errorMessage: 'Cannot create session while offline.',
      );
      return null;
    }

    final repository = ref.read(sessionRepositoryProvider);
    if (repository == null) return null;

    try {
      final session = await repository.createSession(title: title);
      // Invalidate the list to refresh.
      ref.invalidate(sessionListProvider);
      return session.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: SessionsNotifier.createSession — error: $e ===');
      }
      state = state.copyWith(
        errorMessage: 'Failed to create session: $e',
      );
      return null;
    }
  }

  /// Rename a session.
  Future<bool> renameSession(String id, String newTitle) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: SessionsNotifier.renameSession — id=$id, title=$newTitle ===');
    }

    if (state.isOffline) {
      state = state.copyWith(
        errorMessage: 'Cannot rename while offline.',
      );
      return false;
    }

    // Prevent duplicate submissions.
    if (state.isMutating(id)) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: SessionsNotifier.renameSession — blocked: already mutating ===');
      }
      return false;
    }

    state = state.copyWith(
      mutatingSessionIds: {...state.mutatingSessionIds, id},
    );

    final repository = ref.read(sessionRepositoryProvider);
    if (repository == null) return false;

    try {
      await repository.updateSession(id, title: newTitle);
      ref.invalidate(sessionListProvider);
      ref.invalidate(sessionDetailProvider(id));
      state = state.copyWith(
        mutatingSessionIds: state.mutatingSessionIds.difference({id}),
        clearRenameSession: true,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: SessionsNotifier.renameSession — error: $e ===');
      }
      state = state.copyWith(
        mutatingSessionIds: state.mutatingSessionIds.difference({id}),
        errorMessage: 'Failed to rename session: $e',
      );
      return false;
    }
  }

  /// Delete a session (after user confirmation).
  Future<bool> deleteSession(String id) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: SessionsNotifier.deleteSession — id=$id ===');
    }

    if (state.isOffline) {
      state = state.copyWith(
        errorMessage: 'Cannot delete while offline.',
      );
      return false;
    }

    if (state.isMutating(id)) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: SessionsNotifier.deleteSession — blocked: already mutating ===');
      }
      return false;
    }

    state = state.copyWith(
      mutatingSessionIds: {...state.mutatingSessionIds, id},
      deleteConfirmSessionId: null,
      clearDeleteConfirm: true,
    );

    final repository = ref.read(sessionRepositoryProvider);
    if (repository == null) return false;

    try {
      await repository.deleteSession(id);
      ref.invalidate(sessionListProvider);
      state = state.copyWith(
        mutatingSessionIds: state.mutatingSessionIds.difference({id}),
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: SessionsNotifier.deleteSession — error: $e ===');
      }
      state = state.copyWith(
        mutatingSessionIds: state.mutatingSessionIds.difference({id}),
        errorMessage: 'Failed to delete session: $e',
      );
      return false;
    }
  }

  /// Toggle pin on a session.
  Future<void> togglePin(String id, bool currentPinned) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: SessionsNotifier.togglePin — id=$id, pinned=$currentPinned ===');
    }

    if (state.isOffline) return;
    if (state.isMutating(id)) return;

    state = state.copyWith(
      mutatingSessionIds: {...state.mutatingSessionIds, id},
    );

    final repository = ref.read(sessionRepositoryProvider);
    if (repository == null) return;

    try {
      await repository.updateSession(id, isPinned: !currentPinned);
      ref.invalidate(sessionListProvider);
      ref.invalidate(sessionDetailProvider(id));
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: SessionsNotifier.togglePin — error: $e ===');
      }
      state = state.copyWith(
        errorMessage: 'Failed to update session: $e',
      );
    } finally {
      state = state.copyWith(
        mutatingSessionIds: state.mutatingSessionIds.difference({id}),
      );
    }
  }

  /// Toggle archive on a session.
  Future<void> toggleArchive(String id, bool currentArchived) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: SessionsNotifier.toggleArchive — id=$id, archived=$currentArchived ===');
    }

    if (state.isOffline) return;
    if (state.isMutating(id)) return;

    state = state.copyWith(
      mutatingSessionIds: {...state.mutatingSessionIds, id},
    );

    final repository = ref.read(sessionRepositoryProvider);
    if (repository == null) return;

    try {
      await repository.updateSession(id, isArchived: !currentArchived);
      ref.invalidate(sessionListProvider);
      ref.invalidate(sessionDetailProvider(id));
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: SessionsNotifier.toggleArchive — error: $e ===');
      }
      state = state.copyWith(
        errorMessage: 'Failed to update session: $e',
      );
    } finally {
      state = state.copyWith(
        mutatingSessionIds: state.mutatingSessionIds.difference({id}),
      );
    }
  }

  /// Fork a session.
  Future<String?> forkSession(String id) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: SessionsNotifier.forkSession — id=$id ===');
    }

    if (state.isOffline) {
      state = state.copyWith(
        errorMessage: 'Cannot fork while offline.',
      );
      return null;
    }

    if (state.isMutating(id)) return null;

    state = state.copyWith(
      mutatingSessionIds: {...state.mutatingSessionIds, id},
    );

    final repository = ref.read(sessionRepositoryProvider);
    if (repository == null) return null;

    try {
      final newSession = await repository.forkSession(id);
      ref.invalidate(sessionListProvider);
      state = state.copyWith(
        mutatingSessionIds: state.mutatingSessionIds.difference({id}),
      );
      return newSession.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: SessionsNotifier.forkSession — error: $e ===');
      }
      state = state.copyWith(
        mutatingSessionIds: state.mutatingSessionIds.difference({id}),
        errorMessage: 'Failed to fork session: $e',
      );
      return null;
    }
  }

  // ─── Dialog State Management ───

  /// Show delete confirmation for a session.
  void showDeleteConfirmation(String id) {
    state = state.copyWith(deleteConfirmSessionId: id);
  }

  /// Dismiss delete confirmation dialog.
  void dismissDeleteConfirmation() {
    state = state.copyWith(clearDeleteConfirm: true);
  }

  /// Show rename dialog for a session.
  void showRenameDialog(String id) {
    state = state.copyWith(renameSessionId: id);
  }

  /// Dismiss rename dialog.
  void dismissRenameDialog() {
    state = state.copyWith(clearRenameSession: true);
  }
}

/// Provider for the sessions screen UI state notifier.
/// NOT autoDispose — shared long-lived controller.
final sessionsNotifierProvider =
    NotifierProvider<SessionsNotifier, SessionsScreenState>(
  SessionsNotifier.new,
);
