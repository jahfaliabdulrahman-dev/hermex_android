import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/skills/providers/skills_provider.dart';
import 'package:hermex_android/models/skill.dart';

/// Test helper to create a skill.
Skill _createSkill({
  String name = 'test-skill',
  String description = 'A test skill',
  String? category,
  bool enabled = true,
}) {
  return Skill(
    name: name,
    description: description,
    category: category,
    enabled: enabled,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SkillsScreenState — filtering', () {
    test('filteredSkills returns all when no filters active', () {
      final state = SkillsScreenState(
        skills: [
          _createSkill(name: 'alpha-skill', category: 'cat-a'),
          _createSkill(name: 'beta-skill', category: 'cat-b'),
          _createSkill(name: 'gamma-skill', category: 'cat-a'),
        ],
      );

      expect(state.filteredSkills.length, 3);
    });

    test('filteredSkills filters by search query (name match)', () {
      final state = SkillsScreenState(
        skills: [
          _createSkill(name: 'code-review'),
          _createSkill(name: 'write-tests'),
          _createSkill(name: 'debug-app'),
        ],
        searchQuery: 'code',
      );

      expect(state.filteredSkills.length, 1);
      expect(state.filteredSkills.first.name, 'code-review');
    });

    test('filteredSkills filters by search query (description match)', () {
      final state = SkillsScreenState(
        skills: [
          _createSkill(name: 'alpha', description: 'Handles file uploads'),
          _createSkill(name: 'beta', description: 'Manages database'),
          _createSkill(name: 'gamma', description: 'File processing pipeline'),
        ],
        searchQuery: 'file',
      );

      expect(state.filteredSkills.length, 2);
    });

    test('filteredSkills filters by category', () {
      final state = SkillsScreenState(
        skills: [
          _createSkill(name: 'a', category: 'dev'),
          _createSkill(name: 'b', category: 'ops'),
          _createSkill(name: 'c', category: 'dev'),
        ],
        selectedCategory: 'dev',
      );

      expect(state.filteredSkills.length, 2);
      expect(state.filteredSkills.every((s) => s.category == 'dev'), true);
    });

    test('filteredSkills combines search and category filter', () {
      final state = SkillsScreenState(
        skills: [
          _createSkill(name: 'python-dev', category: 'dev'),
          _createSkill(name: 'python-ops', category: 'ops'),
          _createSkill(name: 'js-dev', category: 'dev'),
        ],
        searchQuery: 'python',
        selectedCategory: 'dev',
      );

      expect(state.filteredSkills.length, 1);
      expect(state.filteredSkills.first.name, 'python-dev');
    });

    test('filteredSkills returns empty when no matches', () {
      final state = SkillsScreenState(
        skills: [
          _createSkill(name: 'a'),
          _createSkill(name: 'b'),
        ],
        searchQuery: 'zzz_nonexistent',
      );

      expect(state.filteredSkills, isEmpty);
    });

    test('categories returns sorted unique categories', () {
      final state = SkillsScreenState(
        skills: [
          _createSkill(name: 'a', category: 'dev'),
          _createSkill(name: 'b', category: 'ops'),
          _createSkill(name: 'c', category: 'dev'),
          _createSkill(name: 'd', category: 'ai'),
        ],
      );

      expect(state.categories, ['ai', 'dev', 'ops']);
    });

    test('categories excludes null and empty categories', () {
      final state = SkillsScreenState(
        skills: [
          _createSkill(name: 'a', category: 'dev'),
          _createSkill(name: 'b'),
          _createSkill(name: 'c', category: ''),
        ],
      );

      expect(state.categories, ['dev']);
    });

    test('isToggling returns true when skill is in toggling set', () {
      final state = SkillsScreenState(
        togglingSkills: {'skill-a'},
      );

      expect(state.isToggling('skill-a'), true);
      expect(state.isToggling('skill-b'), false);
    });

    test('copyWith preserves existing values', () {
      final state = SkillsScreenState(
        skills: [_createSkill(name: 'a')],
        searchQuery: 'test',
        selectedCategory: 'cat',
      );

      final updated = state.copyWith(searchQuery: 'new');

      expect(updated.skills.length, 1);
      expect(updated.searchQuery, 'new');
      expect(updated.selectedCategory, 'cat');
    });

    test('copyWith clearCategory clears the category filter', () {
      final state = SkillsScreenState(selectedCategory: 'dev');

      final cleared = state.copyWith(clearCategory: true);

      expect(cleared.selectedCategory, isNull);
    });
  });

  group('SkillsNotifier — basic access', () {
    test('SkillsRepositoryProvider exists and returns non-null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(skillsRepositoryProvider);
      expect(repo, isNotNull);
    });
  });
}
