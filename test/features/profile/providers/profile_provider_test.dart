import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/profile/providers/profile_provider.dart';
import 'package:hermex_android/data/models/hermes_profile.dart';

void main() {
  group('ProfileScreenState', () {
    test('default state has empty profiles', () {
      const state = ProfileScreenState();

      expect(state.profiles, isEmpty);
      expect(state.activeProfile, isNull);
      expect(state.mutatingIds, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.deleteConfirmId, isNull);
      expect(state.dataVersion, 0);
    });

    test('isMutating returns false for non-mutating id', () {
      const state = ProfileScreenState();

      expect(state.isMutating(1), false);
    });

    test('isMutating returns true for mutating id', () {
      final state = ProfileScreenState(mutatingIds: {1, 2, 3});

      expect(state.isMutating(2), true);
      expect(state.isMutating(5), false);
    });

    test('copyWith updates profiles', () {
      const state = ProfileScreenState();
      final profiles = [
        HermesProfile(
          id: 1,
          name: 'Test Profile',
          serverId: 'srv-1',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];

      final updated = state.copyWith(profiles: profiles);

      expect(updated.profiles, hasLength(1));
      expect(updated.profiles.first.name, 'Test Profile');
    });

    test('copyWith updates activeProfile', () {
      const state = ProfileScreenState();
      final profile = HermesProfile(
        id: 1,
        name: 'Active',
        serverId: 'srv-1',
        isActive: true,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final updated = state.copyWith(activeProfile: profile);

      expect(updated.activeProfile?.name, 'Active');
    });

    test('copyWith clearActiveProfile removes active profile', () {
      final profile = HermesProfile(
        id: 1,
        name: 'Active',
        serverId: 'srv-1',
        isActive: true,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final state = ProfileScreenState(activeProfile: profile);

      final updated = state.copyWith(clearActiveProfile: true);

      expect(updated.activeProfile, isNull);
    });

    test('copyWith updates errorMessage', () {
      const state = ProfileScreenState();

      final updated = state.copyWith(errorMessage: 'Something went wrong');

      expect(updated.errorMessage, 'Something went wrong');
    });

    test('copyWith clearError removes error message', () {
      const state = ProfileScreenState(errorMessage: 'Error');

      final updated = state.copyWith(clearError: true);

      expect(updated.errorMessage, isNull);
    });

    test('copyWith updates mutatingIds', () {
      const state = ProfileScreenState();

      final updated = state.copyWith(mutatingIds: {5});

      expect(updated.mutatingIds, {5});
    });

    test('copyWith updates deleteConfirmId', () {
      const state = ProfileScreenState();

      final updated = state.copyWith(deleteConfirmId: 42);

      expect(updated.deleteConfirmId, 42);
    });

    test('copyWith clearDeleteConfirm removes confirmation', () {
      const state = ProfileScreenState(deleteConfirmId: 42);

      final updated = state.copyWith(clearDeleteConfirm: true);

      expect(updated.deleteConfirmId, isNull);
    });

    test('copyWith bumps dataVersion', () {
      const state = ProfileScreenState();

      final updated = state.copyWith(dataVersion: 5);

      expect(updated.dataVersion, 5);
    });
  });
}
