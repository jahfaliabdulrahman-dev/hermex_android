import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_classifier.dart';
import '../../../data/datasources/local/isar_provider.dart';
import '../../../data/models/hermes_profile.dart';
import '../../../data/repositories/hermes_profile_repository.dart';
import '../../connection/providers/connection_provider.dart';

/// Provider for the HermesProfileRepository (DI).
final profileRepositoryProvider = Provider<HermesProfileRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return HermesProfileRepository(isar: isar);
});

/// Fetch all non-deleted HermesProfiles.
final profileListProvider = FutureProvider<List<HermesProfile>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getAll();
});

/// Fetch the currently active HermesProfile.
final activeProfileProvider = FutureProvider<HermesProfile?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getActive();
});

/// Fetch the profile for the currently connected server.
/// Returns null if no server is connected or no profile exists for it.
final currentServerProfileProvider =
    FutureProvider<HermesProfile?>((ref) async {
  final connectionState = ref.watch(connectionProvider);
  final activeServer = connectionState.activeServer;
  if (activeServer == null) return null;

  final repository = ref.watch(profileRepositoryProvider);
  return repository.getByServerId(activeServer.id);
});

// ─── UI State ───

/// Complete UI state for the profile management screen.
class ProfileScreenState {
  /// All non-deleted profiles.
  final List<HermesProfile> profiles;

  /// Currently active profile.
  final HermesProfile? activeProfile;

  /// Set of profile IDs currently having a mutation in-flight.
  final Set<int> mutatingIds;

  /// Error message for toast/error display.
  final String? errorMessage;

  /// Whether a delete confirmation dialog is showing.
  final int? deleteConfirmId;

  /// Monotonically-increasing counter incremented after every successful
  /// mutation. Used by external listeners to trigger provider invalidations
  /// without calling ref.invalidate() from inside the Notifier (ADR-009).
  final int dataVersion;

  const ProfileScreenState({
    this.profiles = const [],
    this.activeProfile,
    this.mutatingIds = const {},
    this.errorMessage,
    this.deleteConfirmId,
    this.dataVersion = 0,
  });

  bool isMutating(int id) => mutatingIds.contains(id);

  ProfileScreenState copyWith({
    List<HermesProfile>? profiles,
    HermesProfile? activeProfile,
    bool clearActiveProfile = false,
    Set<int>? mutatingIds,
    String? errorMessage,
    bool clearError = false,
    int? deleteConfirmId,
    bool clearDeleteConfirm = false,
    int? dataVersion,
  }) =>
      ProfileScreenState(
        profiles: profiles ?? this.profiles,
        activeProfile:
            clearActiveProfile ? null : (activeProfile ?? this.activeProfile),
        mutatingIds: mutatingIds ?? this.mutatingIds,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        deleteConfirmId:
            clearDeleteConfirm ? null : (deleteConfirmId ?? this.deleteConfirmId),
        dataVersion: dataVersion ?? this.dataVersion,
      );
}

/// Notifier for profile CRUD operations and UI state.
///
/// NOT autoDispose — shared, long-lived controller (DEC-034 rule 2).
class ProfileNotifier extends Notifier<ProfileScreenState> {
  @override
  ProfileScreenState build() {
    // Load profiles and active profile on init.
    _loadProfiles();
    return const ProfileScreenState();
  }

  Future<void> _loadProfiles() async {
    final repository = ref.read(profileRepositoryProvider);
    final profiles = await repository.getAll();
    final active = await repository.getActive();
    state = state.copyWith(profiles: profiles, activeProfile: active);
  }

  /// Refresh the profile list from the database.
  Future<void> refreshProfiles() async {
    await _loadProfiles();
  }

  // ─── Mutations ───

  /// Create a new profile.
  Future<HermesProfile?> createProfile({
    required String name,
    required String serverId,
    String? defaultModelId,
    String? reasoningEffort,
    int? thinkingBudgetTokens,
    bool isActive = false,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: ProfileNotifier.createProfile — name=$name ===');
    }

    final repository = ref.read(profileRepositoryProvider);
    try {
      final profile = await repository.create(
        name: name,
        serverId: serverId,
        defaultModelId: defaultModelId,
        reasoningEffort: reasoningEffort,
        thinkingBudgetTokens: thinkingBudgetTokens,
        isActive: isActive,
      );
      // ADR-009: Bump dataVersion instead of calling ref.invalidate() inside Notifier.
      // External listener on profileNotifierProvider invalidates downstream providers.
      await _loadProfiles();
      state = state.copyWith(dataVersion: state.dataVersion + 1);
      return profile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: ProfileNotifier.createProfile — error: $e ===');
      }
      state = state.copyWith(
        errorMessage: 'Failed to create profile: ${ErrorClassifier.sanitizeMessage(e)}',
      );
      return null;
    }
  }

  /// Update an existing profile.
  Future<bool> updateProfile(
    int id, {
    String? name,
    String? defaultModelId,
    String? reasoningEffort,
    int? thinkingBudgetTokens,
    bool? isActive,
    bool clearDefaultModelId = false,
    bool clearReasoningEffort = false,
    bool clearThinkingBudgetTokens = false,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: ProfileNotifier.updateProfile — id=$id ===');
    }

    if (state.isMutating(id)) return false;

    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, id},
    );

    final repository = ref.read(profileRepositoryProvider);
    try {
      await repository.update(
        id,
        name: name,
        defaultModelId: defaultModelId,
        reasoningEffort: reasoningEffort,
        thinkingBudgetTokens: thinkingBudgetTokens,
        isActive: isActive,
        clearDefaultModelId: clearDefaultModelId,
        clearReasoningEffort: clearReasoningEffort,
        clearThinkingBudgetTokens: clearThinkingBudgetTokens,
      );
      // ADR-009: Bump dataVersion — external listener handles provider invalidation.
      await _loadProfiles();
      state = state.copyWith(
        mutatingIds: state.mutatingIds.difference({id}),
        dataVersion: state.dataVersion + 1,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: ProfileNotifier.updateProfile — error: $e ===');
      }
      state = state.copyWith(
        mutatingIds: state.mutatingIds.difference({id}),
        errorMessage: 'Failed to update profile: ${ErrorClassifier.sanitizeMessage(e)}',
      );
      return false;
    }
  }

  /// Set a profile as active.
  Future<bool> setActiveProfile(int id) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: ProfileNotifier.setActiveProfile — id=$id ===');
    }

    if (state.isMutating(id)) return false;

    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, id},
    );

    final repository = ref.read(profileRepositoryProvider);
    try {
      await repository.setActive(id);
      // ADR-009: Bump dataVersion — external listener handles provider invalidation.
      await _loadProfiles();
      state = state.copyWith(
        mutatingIds: state.mutatingIds.difference({id}),
        dataVersion: state.dataVersion + 1,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: ProfileNotifier.setActiveProfile — error: $e ===');
      }
      state = state.copyWith(
        mutatingIds: state.mutatingIds.difference({id}),
        errorMessage: 'Failed to set active profile: ${ErrorClassifier.sanitizeMessage(e)}',
      );
      return false;
    }
  }

  /// Soft-delete a profile.
  Future<bool> deleteProfile(int id) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: ProfileNotifier.deleteProfile — id=$id ===');
    }

    if (state.isMutating(id)) return false;

    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, id},
      clearDeleteConfirm: true,
    );

    final repository = ref.read(profileRepositoryProvider);
    try {
      await repository.softDelete(id);
      // ADR-009: Bump dataVersion — external listener handles provider invalidation.
      await _loadProfiles();
      state = state.copyWith(
        mutatingIds: state.mutatingIds.difference({id}),
        dataVersion: state.dataVersion + 1,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: ProfileNotifier.deleteProfile — error: $e ===');
      }
      state = state.copyWith(
        mutatingIds: state.mutatingIds.difference({id}),
        errorMessage: 'Failed to delete profile: ${ErrorClassifier.sanitizeMessage(e)}',
      );
      return false;
    }
  }

  /// Ensure a profile exists for the given server.
  /// Idempotent — creates if missing, activates if existing.
  Future<HermesProfile?> ensureProfileForServer({
    required String serverId,
    required String name,
    String? defaultModelId,
  }) async {
    final repository = ref.read(profileRepositoryProvider);
    try {
      final profile = await repository.ensureProfileForServer(
        serverId: serverId,
        name: name,
        defaultModelId: defaultModelId,
      );
      // ADR-009: Bump dataVersion — external listener handles provider invalidation.
      await _loadProfiles();
      state = state.copyWith(dataVersion: state.dataVersion + 1);
      return profile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: ProfileNotifier.ensureProfileForServer — error: $e ===');
      }
      return null;
    }
  }

  // ─── Error Handling ───

  /// Clear any error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ─── Dialog State ───

  /// Show delete confirmation for a profile.
  void showDeleteConfirmation(int id) {
    state = state.copyWith(deleteConfirmId: id);
  }

  /// Dismiss delete confirmation dialog.
  void dismissDeleteConfirmation() {
    state = state.copyWith(clearDeleteConfirm: true);
  }
}

/// Provider for the profile screen UI state notifier.
/// NOT autoDispose — shared long-lived controller.
final profileNotifierProvider =
    NotifierProvider<ProfileNotifier, ProfileScreenState>(
  ProfileNotifier.new,
);

/// Listens for dataVersion bumps in [profileNotifierProvider] and invalidates
/// downstream profile-list providers. This replaces the ADR-009-violating
/// ref.invalidate() calls that were previously inside ProfileNotifier.
///
/// Must be initialized early (e.g., in the app shell or profile screen)
/// so mutations are reflected in profileListProvider / activeProfileProvider.
final profileInvalidationListener = Provider<void>((ref) {
  // Watch the notifier's dataVersion — when it changes, invalidate downstream.
  ref.listen(profileNotifierProvider, (prev, next) {
    if (prev?.dataVersion != next.dataVersion && next.dataVersion > 0) {
      ref.invalidate(profileListProvider);
      ref.invalidate(activeProfileProvider);
      ref.invalidate(currentServerProfileProvider);
    }
  });
});
