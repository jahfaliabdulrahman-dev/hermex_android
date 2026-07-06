import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../models/skill.dart';
import '../data/skills_repository.dart';

/// Provider for the SkillsRepository (DI via apiClientProvider).
final skillsRepositoryProvider = Provider<SkillsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SkillsRepository(apiClient: apiClient);
});

/// Fetch the list of installed skills from the server.
/// FutureProvider: handles loading/error/data states automatically.
final skillsListProvider = FutureProvider<List<Skill>>((ref) {
  final repository = ref.watch(skillsRepositoryProvider);
  return repository.getSkills();
});

/// UI state for skills screen filtering and toggling.
class SkillsScreenState {
  /// The full unfiltered list of skills.
  final List<Skill> skills;

  /// Current search query (filters by name or description).
  final String searchQuery;

  /// Selected category filter, or null for all.
  final String? selectedCategory;

  /// Set of skill names currently having a toggle in-flight.
  final Set<String> togglingSkills;

  const SkillsScreenState({
    this.skills = const [],
    this.searchQuery = '',
    this.selectedCategory,
    this.togglingSkills = const {},
  });

  /// Filtered skills based on search query and category.
  List<Skill> get filteredSkills {
    var filtered = skills;
    final query = searchQuery.toLowerCase().trim();

    if (query.isNotEmpty) {
      filtered = filtered.where((s) {
        return s.name.toLowerCase().contains(query) ||
            s.description.toLowerCase().contains(query);
      }).toList();
    }

    if (selectedCategory != null) {
      filtered = filtered.where((s) => s.category == selectedCategory).toList();
    }

    return filtered;
  }

  /// All unique categories from the skills list.
  List<String> get categories {
    return skills
        .where((s) => s.category != null && s.category!.isNotEmpty)
        .map((s) => s.category!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Whether a skill is currently being toggled.
  bool isToggling(String name) => togglingSkills.contains(name);

  SkillsScreenState copyWith({
    List<Skill>? skills,
    String? searchQuery,
    String? selectedCategory,
    bool clearCategory = false,
    Set<String>? togglingSkills,
  }) {
    return SkillsScreenState(
      skills: skills ?? this.skills,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      togglingSkills: togglingSkills ?? this.togglingSkills,
    );
  }
}

/// Notifier for skills screen UI state (search, filter, toggle).
class SkillsNotifier extends Notifier<SkillsScreenState> {
  @override
  SkillsScreenState build() {
    _syncFromProvider();
    return const SkillsScreenState();
  }

  /// Sync skills list from the FutureProvider into local state.
  void syncFromProvider() {
    final skillsAsync = ref.read(skillsListProvider);
    skillsAsync.whenData((skills) {
      state = state.copyWith(skills: skills);
    });
  }

  void _syncFromProvider() => syncFromProvider();

  /// Update the search query.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Set the category filter (or clear it).
  void setCategory(String? category) {
    state = state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
    );
  }

  /// Toggle a skill's enabled state.
  /// Currently a local-only toggle for MVP — API mutation not yet implemented.
  Future<void> toggleSkill(String name) async {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: SkillsNotifier.toggleSkill — name=$name ===');
    }

    if (state.isToggling(name)) {
      return;
    }

    // Mark as toggling.
    state = state.copyWith(
      togglingSkills: {...state.togglingSkills, name},
    );

    try {
      // Local optimistic toggle — update the skill's enabled flag.
      final updatedSkills = state.skills.map((s) {
        if (s.name == name) {
          return s.copyWith(enabled: !s.enabled);
        }
        return s;
      }).toList();

      state = state.copyWith(
        skills: updatedSkills,
        togglingSkills: state.togglingSkills.difference({name}),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: SkillsNotifier.toggleSkill — error: $e ===');
      }
      state = state.copyWith(
        togglingSkills: state.togglingSkills.difference({name}),
      );
    }
  }
}

/// Provider for the skills screen UI state.
final skillsNotifierProvider =
    NotifierProvider<SkillsNotifier, SkillsScreenState>(
  SkillsNotifier.new,
);
