import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/hermes_theme_tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/session_summary.dart';
import '../providers/session_provider.dart';

/// Session detail screen — view and manage a single Hermes Agent session.
///
/// States handled: Loading, Error, Success (detail), Offline.
/// Features: editable title, pin/unpin, archive, delete, fork, message preview.
class SessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionDetailProvider(widget.sessionId));
    final uiState = ref.watch(sessionsNotifierProvider);
    final theme = Theme.of(context);

    // Show error snackbar from notifier.
    ref.listen<SessionsScreenState>(sessionsNotifierProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    // Rename dialog listener.
    ref.listen<SessionsScreenState>(sessionsNotifierProvider, (prev, next) {
      if (next.renameSessionId == widget.sessionId &&
          next.renameSessionId != prev?.renameSessionId) {
        _showRenameDialog(sessionAsync.valueOrNull?.title);
      }
    });

    // Delete confirmation listener.
    ref.listen<SessionsScreenState>(sessionsNotifierProvider, (prev, next) {
      if (next.deleteConfirmSessionId == widget.sessionId &&
          next.deleteConfirmSessionId != prev?.deleteConfirmSessionId) {
        _showDeleteDialog();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).colorScheme.onSurface,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.sessions);
            }
          },
        ),
      ),
      body: sessionAsync.when(
        loading: () => _buildLoadingState(theme),
        error: (error, stack) => _buildErrorState(error.toString(), theme),
        data: (session) => _buildContent(session, uiState, theme),
      ),
    );
  }

  // ─── Content ───

  Widget _buildContent(
      SessionSummary session, SessionsScreenState uiState, ThemeData theme) {
    final isMutating = uiState.isMutating(widget.sessionId);
    final isActive = session.status == 'active' || session.status == 'running';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Card ───
          _buildHeaderCard(session, isActive, theme),

          const SizedBox(height: 16),

          // ─── Action Buttons ───
          _buildActionButtons(session, uiState, isMutating, theme),

          const SizedBox(height: 24),

          // ─── Details Section ───
          _buildDetailsSection(session, theme),

          const SizedBox(height: 24),

          // ─── Message Preview ───
          _buildMessagePreview(session, theme),

          const SizedBox(height: 24),

          // ─── Open in Chat ───
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () {
                context.go(RoutePaths.chat);
              },
              icon: const Icon(Icons.chat_bubble),
              label: const Text(AppStrings.openChat),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Header Card ───

  Widget _buildHeaderCard(
      SessionSummary session, bool isActive, ThemeData theme) {
    final displayTitle = session.title ?? 'Untitled';

    return Card(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isActive ? HermesThemeTokens.of(context).success.withValues(alpha: 0.3) : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row.
            Row(
              children: [
                if (isActive) ...[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: HermesThemeTokens.of(context).success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(sessionsNotifierProvider.notifier)
                          .showRenameDialog(widget.sessionId);
                    },
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayTitle,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (isActive) ...[
              const SizedBox(height: 4),
              Text(
                'Active',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: HermesThemeTokens.of(context).success,
                ),
              ),
            ],

            if (session.status != null && !isActive) ...[
              const SizedBox(height: 4),
              Text(
                session.status!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Model and message count.
            Row(
              children: [
                if (session.modelName != null) ...[
                  _infoChip(
                    Icons.smart_toy_outlined,
                    session.modelName!,
                    theme,
                  ),
                  const SizedBox(width: 12),
                ],
                _infoChip(
                  Icons.chat_bubble_outline,
                  '${session.messageCount} messages',
                  theme,
                ),
                const Spacer(),
                // Pin indicator.
                if (session.isPinned)
                  Icon(Icons.push_pin, color: Theme.of(context).colorScheme.secondary, size: 18),
                const SizedBox(width: 4),
                // Archive indicator.
                if (session.isArchived)
                  Icon(Icons.archive, color: HermesThemeTokens.of(context).warning, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ─── Action Buttons ───

  Widget _buildActionButtons(
    SessionSummary session,
    SessionsScreenState uiState,
    bool isMutating,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: session.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            label: session.isPinned ? 'Unpin' : 'Pin',
            color: Theme.of(context).colorScheme.secondary,
            enabled: !isMutating && !uiState.isOffline,
            onPressed: () {
              ref
                  .read(sessionsNotifierProvider.notifier)
                  .togglePin(session.id, session.isPinned);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: session.isArchived ? Icons.unarchive : Icons.archive,
            label: session.isArchived ? 'Unarchive' : 'Archive',
            color: HermesThemeTokens.of(context).warning,
            enabled: !isMutating && !uiState.isOffline,
            onPressed: () {
              ref
                  .read(sessionsNotifierProvider.notifier)
                  .toggleArchive(session.id, session.isArchived);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: Icons.call_split,
            label: 'Fork',
            color: HermesThemeTokens.of(context).info,
            enabled: !isMutating && !uiState.isOffline,
            onPressed: () {
              ref
                  .read(sessionsNotifierProvider.notifier)
                  .forkSession(session.id);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: Theme.of(context).colorScheme.error,
            enabled: !isMutating && !uiState.isOffline,
            onPressed: () {
              ref
                  .read(sessionsNotifierProvider.notifier)
                  .showDeleteConfirmation(widget.sessionId);
            },
          ),
        ),
      ],
    );
  }

  // ─── Details Section ───

  Widget _buildDetailsSection(SessionSummary session, ThemeData theme) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _detailRow(
                'Session ID', session.id.substring(0, 8), theme),
            const SizedBox(height: 8),
            if (session.createdAt != null) ...[
              _detailRow(
                'Created',
                DateFormatter.dateAndTime(session.createdAt!),
                theme,
              ),
              const SizedBox(height: 8),
            ],
            if (session.lastActivity != null) ...[
              _detailRow(
                'Last Activity',
                DateFormatter.dateAndTime(session.lastActivity!),
                theme,
              ),
              const SizedBox(height: 8),
            ],
            _detailRow(
              'Messages',
              '${session.messageCount}',
              theme,
            ),
            if (session.status != null) ...[
              const SizedBox(height: 8),
              _detailRow('Status', session.status!, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Message Preview ───

  Widget _buildMessagePreview(SessionSummary session, ThemeData theme) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (session.messageCount == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Empty session — no messages yet.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Text(
                '${session.messageCount} messages in this session.\n'
                'Open in Chat to view full conversation.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── State Widgets ───

  Widget _buildLoadingState(ThemeData theme) {
    return const Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildErrorState(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.sessionNotFound,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(sessionDetailProvider(widget.sessionId));
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text(AppStrings.retry),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(RoutePaths.sessions);
                    }
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text(AppStrings.goBack),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dialogs ───

  void _showRenameDialog(String? currentTitle) {
    final controller = TextEditingController(text: currentTitle ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Session'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: const InputDecoration(
            hintText: 'Enter new title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(sessionsNotifierProvider.notifier)
                  .dismissRenameDialog();
            },
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isEmpty) return;

              Navigator.of(ctx).pop();
              await ref
                  .read(sessionsNotifierProvider.notifier)
                  .renameSession(widget.sessionId, newTitle);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteSession),
        content: const Text(AppStrings.deleteSessionConfirm),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(sessionsNotifierProvider.notifier)
                  .dismissDeleteConfirmation();
            },
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(sessionsNotifierProvider.notifier)
                  .deleteSession(widget.sessionId)
                  .then((success) {
                if (success && mounted) {
                  context.go(RoutePaths.sessions);
                }
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button Widget ───

/// A compact action button for the session detail action bar.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
        side: BorderSide(
          color: enabled ? color.withValues(alpha: 0.5) : Theme.of(context).colorScheme.outline,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
