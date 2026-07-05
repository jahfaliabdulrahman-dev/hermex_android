import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/colors.dart';
import '../../../models/workspace_entry.dart';
import '../providers/workspace_provider.dart';

/// Workspace Browser screen — browse server filesystem via API.
///
/// States handled:
/// - Loading: shows spinner
/// - Error: shows error with retry
/// - Empty: shows "This directory is empty"
/// - Success: shows file/directory list with breadcrumbs
///
/// Edge cases:
/// - Large directory → ListView.builder with virtual scroll (anti-freeze)
/// - Binary files → "Cannot preview binary file" message
/// - Permission denied → appropriate error message
/// - Deep nesting → breadcrumb trail truncation
class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  @override
  Widget build(BuildContext context) {
    final browserState = ref.watch(workspaceBrowserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: HermesColors.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppStrings.workspace,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: HermesColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: HermesColors.textSecondary),
            onPressed: () {
              final path = ref.read(workspaceBrowserProvider).currentPath;
              ref.invalidate(directoryContentsProvider(path));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Breadcrumb Trail ───
          _buildBreadcrumbs(theme, browserState),

          // ─── Content ───
          Expanded(
            child: browserState.selectedFilePath != null
                ? _buildFilePreview(theme, browserState)
                : _buildDirectoryContents(theme, browserState),
          ),
        ],
      ),
    );
  }

  // ─── Breadcrumbs ───

  Widget _buildBreadcrumbs(ThemeData theme, WorkspaceBrowserState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: HermesColors.surface,
        border: Border(
          bottom: BorderSide(color: HermesColors.border),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Root breadcrumb
            _BreadcrumbChip(
              label: '/',
              isActive: state.pathSegments.isEmpty,
              onTap: () {
                ref
                    .read(workspaceBrowserProvider.notifier)
                    .navigateToSegment(-1);
              },
            ),
            // Path segments
            ...List.generate(state.pathSegments.length, (index) {
              final isLast = index == state.pathSegments.length - 1;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: HermesColors.textDisabled,
                  ),
                  _BreadcrumbChip(
                    label: state.pathSegments[index],
                    isActive: isLast,
                    onTap: () {
                      ref
                          .read(workspaceBrowserProvider.notifier)
                          .navigateToSegment(index);
                    },
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── Directory Contents ───

  Widget _buildDirectoryContents(
      ThemeData theme, WorkspaceBrowserState state) {
    final contentsAsync =
        ref.watch(directoryContentsProvider(state.currentPath));

    return contentsAsync.when(
      loading: () => _buildLoadingState(theme),
      error: (error, _) => _buildErrorState(theme, error),
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmptyState(theme);
        }
        return _buildEntryList(theme, entries, state);
      },
    );
  }

  Widget _buildEntryList(
      ThemeData theme, List<WorkspaceEntry> entries, WorkspaceBrowserState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length + (state.currentPath.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        // First item: ".." back button if not at root.
        if (index == 0 && state.currentPath.isNotEmpty) {
          return _ParentFolderTile(
            onTap: () {
              ref.read(workspaceBrowserProvider.notifier).navigateUp();
            },
          );
        }

        final entryIndex =
            state.currentPath.isNotEmpty ? index - 1 : index;
        final entry = entries[entryIndex];

        return _FileEntryTile(
          entry: entry,
          onTap: () {
            if (entry.type == 'directory') {
              ref
                  .read(workspaceBrowserProvider.notifier)
                  .navigateInto(entry.name);
            } else {
              ref
                  .read(workspaceBrowserProvider.notifier)
                  .selectFile(entry.name);
            }
          },
        );
      },
    );
  }

  // ─── File Preview ───

  Widget _buildFilePreview(ThemeData theme, WorkspaceBrowserState state) {
    final contentAsync =
        ref.watch(fileContentProvider(state.selectedFilePath!));

    return Column(
      children: [
        // Preview header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: HermesColors.surface,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  state.selectedFilePath!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: HermesColors.cyan,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: HermesColors.textSecondary),
                onPressed: () {
                  ref
                      .read(workspaceBrowserProvider.notifier)
                      .clearSelection();
                },
                tooltip: AppStrings.close,
              ),
            ],
          ),
        ),
        // Preview content
        Expanded(
          child: contentAsync.when(
            loading: () => _buildLoadingState(theme),
            error: (error, _) => _buildPreviewError(theme, error),
            data: (content) => _buildPreviewContent(theme, content),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewContent(ThemeData theme, String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: HermesColors.textPrimary,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPreviewError(ThemeData theme, Object error) {
    final message = error.toString();
    final isBinary = message.contains('binary');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBinary ? Icons.insert_drive_file_outlined : Icons.error_outline,
              color: isBinary ? HermesColors.warning : HermesColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isBinary ? AppStrings.cannotPreviewFileType : AppStrings.failedToLoadDirectory,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isBinary ? HermesColors.warning : HermesColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: HermesColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── States ───

  Widget _buildLoadingState(ThemeData theme) {
    return const Center(
      child: CircularProgressIndicator(color: HermesColors.cyan),
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
              AppStrings.failedToLoadDirectory,
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
              onPressed: () {
                ref.read(workspaceBrowserProvider.notifier).refresh();
              },
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
              Icons.folder_open,
              color: HermesColors.textDisabled,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.emptyDirectory,
              style: theme.textTheme.titleMedium?.copyWith(
                color: HermesColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-Widgets ───

/// Breadcrumb chip component.
class _BreadcrumbChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BreadcrumbChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? HermesColors.cyan : HermesColors.textSecondary,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}

/// ".." parent folder navigation tile.
class _ParentFolderTile extends StatelessWidget {
  final VoidCallback onTap;

  const _ParentFolderTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.arrow_upward, color: HermesColors.cyan),
      title: Text(
        '..',
        style: TextStyle(color: HermesColors.textPrimary),
      ),
      onTap: onTap,
    );
  }
}

/// File/directory entry tile.
class _FileEntryTile extends StatelessWidget {
  final WorkspaceEntry entry;
  final VoidCallback onTap;

  const _FileEntryTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDirectory = entry.type == 'directory';
    final isBinary = entry.isBinary;

    return ListTile(
      leading: Icon(
        isDirectory ? Icons.folder : Icons.insert_drive_file_outlined,
        color: isDirectory ? HermesColors.warning : HermesColors.textSecondary,
      ),
      title: Text(
        entry.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: HermesColors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (!isDirectory) ...[
            Text(
              _formatSize(entry.size),
              style: theme.textTheme.bodySmall?.copyWith(
                color: HermesColors.textDisabled,
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (entry.modifiedAt != null)
            Flexible(
              child: Text(
                entry.modifiedAt!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: HermesColors.textDisabled,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (isBinary) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: HermesColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'binary',
                style: TextStyle(
                  fontSize: 10,
                  color: HermesColors.warning,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: isDirectory
          ? Icon(Icons.chevron_right, color: HermesColors.textDisabled)
          : null,
      onTap: onTap,
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
