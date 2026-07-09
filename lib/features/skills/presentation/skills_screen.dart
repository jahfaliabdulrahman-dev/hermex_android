import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/colors.dart';
import '../../../models/skill.dart';
import '../providers/skills_provider.dart';

/// Skills Browser screen — lists installed skills with search, filter, and toggle.
///
/// States handled:
/// - Loading: shows shimmer/spinner
/// - Error: shows error message with retry
/// - Empty: shows "No skills installed" message
/// - Success: shows filtered skill list
///
/// Edge cases:
/// - No skills installed → helpful message with context
/// - Search with no results → empty state with search context
/// - Skills list from server could be large → virtual scroll via ListView.builder
class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  final _searchController = TextEditingController();
  int? _expandedIndex;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(skillsListProvider);
    final screenState = ref.watch(skillsNotifierProvider);
    final theme = Theme.of(context);

    // Sync skills from provider to local state when data arrives.
    ref.listen(skillsListProvider, (_, next) {
      ref.read(skillsNotifierProvider.notifier).syncFromProvider();
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppStrings.skills,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: HermesColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ─── Search Bar ───
          _buildSearchBar(theme, screenState),

          // ─── Category Chips ───
          if (screenState.categories.isNotEmpty)
            _buildCategoryChips(theme, screenState),

          // ─── Content ───
          Expanded(
            child: skillsAsync.when(
              loading: () => _buildLoadingState(theme),
              error: (error, _) => _buildErrorState(theme, error),
              data: (skills) {
                if (skills.isEmpty) {
                  return _buildEmptyState(theme);
                }
                return _buildSkillsList(theme, screenState);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Widget Builders ───

  Widget _buildSearchBar(ThemeData theme, SkillsScreenState screenState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref.read(skillsNotifierProvider.notifier).setSearchQuery(value);
        },
        style: TextStyle(color: HermesColors.textPrimary),
        decoration: InputDecoration(
          hintText: AppStrings.searchSkills,
          hintStyle: TextStyle(color: HermesColors.textDisabled),
          prefixIcon: Icon(Icons.search, color: HermesColors.textSecondary),
          suffixIcon: screenState.searchQuery.isNotEmpty
              ? IconButton(
                  icon:
                      Icon(Icons.clear, color: HermesColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    ref
                        .read(skillsNotifierProvider.notifier)
                        .setSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: HermesColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: HermesColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: HermesColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: HermesColors.cyan, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme, SkillsScreenState screenState) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          _buildCategoryChip(
            theme: theme,
            label: 'All',
            isSelected: screenState.selectedCategory == null,
            onTap: () {
              ref.read(skillsNotifierProvider.notifier).setCategory(null);
            },
          ),
          ...screenState.categories.map(
            (category) => _buildCategoryChip(
              theme: theme,
              label: category,
              isSelected: screenState.selectedCategory == category,
              onTap: () {
                ref.read(skillsNotifierProvider.notifier).setCategory(category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required ThemeData theme,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: HermesColors.cyan,
        checkmarkColor: HermesColors.dark,
        labelStyle: TextStyle(
          color: isSelected ? HermesColors.dark : HermesColors.textPrimary,
          fontSize: 13,
        ),
        backgroundColor: HermesColors.surface,
        side: BorderSide(
          color: isSelected ? HermesColors.cyan : HermesColors.border,
        ),
      ),
    );
  }

  Widget _buildSkillsList(ThemeData theme, SkillsScreenState screenState) {
    final filtered = screenState.filteredSkills;

    if (filtered.isEmpty) {
      return _buildEmptySearchState(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final skill = filtered[index];
        final isExpanded = _expandedIndex == index;
        final isToggling = screenState.isToggling(skill.name);

        return _SkillCard(
          skill: skill,
          isExpanded: isExpanded,
          isToggling: isToggling,
          onTap: () {
            setState(() {
              _expandedIndex = isExpanded ? null : index;
            });
          },
          onToggle: () {
            ref
                .read(skillsNotifierProvider.notifier)
                .toggleSkill(skill.name);
          },
        );
      },
    );
  }

  // ─── States ───

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: HermesColors.cyan),
          const SizedBox(height: 16),
          Text(
            AppStrings.loading,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: HermesColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: HermesColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              AppStrings.failedToLoadSkills,
              style: theme.textTheme.titleMedium?.copyWith(
                color: HermesColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: HermesColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(skillsListProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppStrings.retry),
              style: FilledButton.styleFrom(
                backgroundColor: HermesColors.cyan,
                foregroundColor: HermesColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.extension_outlined,
              color: HermesColors.textDisabled,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noSkillsInstalled,
              style: theme.textTheme.titleMedium?.copyWith(
                color: HermesColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.installSkillsOnServer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: HermesColors.textDisabled,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: HermesColors.textDisabled, size: 48),
            const SizedBox(height: 16),
            Text(
              'No skills match your search.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: HermesColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                ref
                    .read(skillsNotifierProvider.notifier)
                    .setSearchQuery('');
                ref.read(skillsNotifierProvider.notifier).setCategory(null);
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single skill card with expand/collapse and toggle.
class _SkillCard extends StatelessWidget {
  final Skill skill;
  final bool isExpanded;
  final bool isToggling;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _SkillCard({
    required this.skill,
    required this.isExpanded,
    required this.isToggling,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: HermesColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: HermesColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header Row ───
              Row(
                children: [
                  // Toggle switch
                  SizedBox(
                    width: 40,
                    height: 24,
                    child: isToggling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: HermesColors.cyan,
                            ),
                          )
                        : Switch(
                            value: skill.enabled,
                            onChanged: (_) => onToggle(),
                            activeTrackColor: HermesColors.cyan,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Name
                  Expanded(
                    child: Text(
                      skill.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: HermesColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Expand icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: HermesColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // ─── Badges Row ───
              if (skill.category != null || skill.sourceReputation != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (skill.category != null)
                      _Badge(
                        label: skill.category!,
                        color: HermesColors.cyan,
                      ),
                    if (skill.sourceReputation != null)
                      _Badge(
                        label: skill.sourceReputation!,
                        color: HermesColors.info,
                      ),
                    if (skill.snippetCount > 0)
                      _Badge(
                        label: '${skill.snippetCount} snippets',
                        color: HermesColors.success,
                      ),
                  ],
                ),
              ],

              // ─── Expanded Description ───
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (skill.description.isNotEmpty)
                        Text(
                          skill.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: HermesColors.textSecondary,
                          ),
                        ),
                      if (skill.benchmarkScore > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.speed,
                                size: 14, color: HermesColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Benchmark: ${skill.benchmarkScore}/100',
                              style:
                                  theme.textTheme.bodySmall?.copyWith(
                                color: HermesColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),

              // ─── Short preview when collapsed ───
              if (!isExpanded && skill.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  skill.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: HermesColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small colored badge for categories and metadata.
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
