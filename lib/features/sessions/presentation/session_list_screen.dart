import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/session_summary.dart';
import '../providers/session_provider.dart';

/// Sessions screen — browse, search, and manage Hermes Agent sessions.
///
/// States handled: Loading (skeleton), Empty, Error, Success, Offline.
/// Edge cases:
/// - Empty list → helpful text + "New Chat" CTA
/// - Network error → cached sessions with "offline" badge
/// - Delete confirmation dialog
/// - Long titles → ellipsis (max 80 chars)
/// - Archived sessions → separate section / filter toggle
/// - Pinned sessions at top
class SessionListScreen extends ConsumerStatefulWidget {
  const SessionListScreen({super.key});

  @override
  ConsumerState<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends ConsumerState<SessionListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Actions ───

  Future<void> _handleCreateSession() async {
    final sessionId =
        await ref.read(sessionsNotifierProvider.notifier).createSession();
    if (sessionId != null && mounted) {
      context.go(RoutePaths.chat); // Navigate to chat with the new session.
    }
  }

  Future<void> _handleDeleteSession(String id) async {
    final success =
        await ref.read(sessionsNotifierProvider.notifier).deleteSession(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session deleted')),
      );
    }
  }

  void _handleSessionTap(String id) {
    context.go(RoutePaths.sessionById(id));
  }

  // ─── Filtering ───

  /// Filter and sort sessions client-side based on UI state.
  List<SessionSummary> _filterSessions(
    List<SessionSummary> sessions,
    SessionsScreenState uiState,
  ) {
    var filtered = sessions;

    // Filter archived vs active.
    if (uiState.showArchived) {
      filtered = filtered.where((s) => s.isArchived).toList();
    } else {
      filtered = filtered.where((s) => !s.isArchived).toList();
    }

    // Search filter (case-insensitive).
    final query = uiState.searchQuery.toLowerCase().trim();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              (s.title ?? '').toLowerCase().contains(query) ||
              (s.modelName ?? '').toLowerCase().contains(query))
          .toList();
    }

    // Sort: pinned first, then by last activity (newest first).
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      final aTime = a.lastActivity?.millisecondsSinceEpoch ?? 0;
      final bTime = b.lastActivity?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return filtered;
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionListProvider);
    final uiState = ref.watch(sessionsNotifierProvider);

    // Show error snackbar when error state changes.
    ref.listen<SessionsScreenState>(sessionsNotifierProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: HermesColors.error,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });

    // Delete confirmation dialog.
    ref.listen<SessionsScreenState>(sessionsNotifierProvider, (prev, next) {
      if (next.deleteConfirmSessionId != null &&
          next.deleteConfirmSessionId != prev?.deleteConfirmSessionId) {
        _showDeleteDialog(next.deleteConfirmSessionId!);
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppStrings.sessions,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          // Archive toggle.
          IconButton(
            icon: Icon(
              uiState.showArchived ? Icons.archive : Icons.archive_outlined,
              color: uiState.showArchived
                  ? HermesColors.cyan
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            tooltip: uiState.showArchived
                ? 'Show Active'
                : 'Show Archived',
            onPressed: () {
              ref.read(sessionsNotifierProvider.notifier).toggleShowArchived();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search Bar ───
          _buildSearchBar(uiState),

          // ─── Offline Banner ───
          if (uiState.isOffline) _buildOfflineBanner(),

          // ─── Session List ───
          Expanded(
            child: sessionsAsync.when(
              loading: () => _buildLoadingSkeleton(),
              error: (error, stack) =>
                  _buildErrorState(error.toString()),
              data: (sessions) {
                final filtered = _filterSessions(sessions, uiState);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildSessionList(filtered);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: uiState.isOffline
          ? null
          : FloatingActionButton.extended(
              onPressed: _handleCreateSession,
              icon: Icon(Icons.add),
              label: Text('New Chat'),
            ),
    );
  }

  // ─── Widget Builders ───

  Widget _buildSearchBar(SessionsScreenState uiState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref.read(sessionsNotifierProvider.notifier).setSearchQuery(value);
        },
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: AppStrings.searchSessions,
          hintStyle: TextStyle(color: HermesColors.textDisabled),
          prefixIcon:
              Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  onPressed: () {
                    _searchController.clear();
                    ref
                        .read(sessionsNotifierProvider.notifier)
                        .setSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: HermesColors.cyan, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: HermesColors.warning.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: HermesColors.warning, size: 16),
          SizedBox(width: 8),
          Text(
            AppStrings.offlineCachedData,
            style: TextStyle(
              color: HermesColors.warning,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(List<SessionSummary> sessions) {
    return RefreshIndicator(
      color: HermesColors.cyan,
      onRefresh: () async {
        ref.invalidate(sessionListProvider);
        await ref.read(sessionListProvider.future);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _SessionCard(
            session: session,
            onTap: () => _handleSessionTap(session.id),
            onDelete: () => _handleDeleteSession(session.id),
          );
        },
      ),
    );
  }

  // ─── State Widgets ───

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title skeleton.
                  Container(
                    height: 16,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Subtitle skeleton.
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final uiState = ref.read(sessionsNotifierProvider);
    final String message;
    final String? actionLabel;

    if (uiState.showArchived) {
      message = 'No archived sessions.';
      actionLabel = null;
    } else if (uiState.searchQuery.isNotEmpty) {
      message = 'No sessions match "${uiState.searchQuery}".';
      actionLabel = 'Clear Search';
    } else {
      message = AppStrings.startChatForFirstSession;
      actionLabel = 'New Chat';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              uiState.showArchived
                  ? Icons.archive_outlined
                  : Icons.forum_outlined,
              size: 64,
              color: HermesColors.textDisabled,
            ),
            SizedBox(height: 16),
            Text(
              uiState.showArchived
                  ? 'No Archived Sessions'
                  : AppStrings.noSessionsYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HermesColors.textDisabled,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            if (actionLabel != null)
              ElevatedButton.icon(
                onPressed: () {
                  if (uiState.searchQuery.isNotEmpty) {
                    _searchController.clear();
                    ref
                        .read(sessionsNotifierProvider.notifier)
                        .setSearchQuery('');
                  } else {
                    _handleCreateSession();
                  }
                },
                icon: Icon(
                  uiState.searchQuery.isNotEmpty
                      ? Icons.clear
                      : Icons.add,
                  size: 18,
                ),
                label: Text(actionLabel),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: HermesColors.error,
            ),
            SizedBox(height: 16),
            Text(
              AppStrings.failedToLoadSessions,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: HermesColors.error,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(sessionListProvider);
              },
              icon: Icon(Icons.refresh, size: 18),
              label: Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dialogs ───

  void _showDeleteDialog(String sessionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppStrings.deleteSession),
        content: Text(AppStrings.deleteSessionConfirm),
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(sessionsNotifierProvider.notifier)
                  .dismissDeleteConfirmation();
              Navigator.of(ctx).pop();
            },
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleDeleteSession(sessionId);
            },
            style: TextButton.styleFrom(
              foregroundColor: HermesColors.error,
            ),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

// ─── Session Card Widget ───

/// A single session card in the list.
///
/// Displays: title, model name, message count, last activity (relative time),
/// pin/archive indicators, and active status dot.
class _SessionCard extends ConsumerWidget {
  final SessionSummary session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(sessionsNotifierProvider);
    final theme = Theme.of(context);
    final isActive = session.status == 'active' || session.status == 'running';

    // Truncate long titles.
    final displayTitle = _truncateTitle(session.title);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(session.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: HermesColors.error.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete, color: HermesColors.white),
        ),
        confirmDismiss: (direction) async {
          ref
              .read(sessionsNotifierProvider.notifier)
              .showDeleteConfirmation(session.id);
          return false; // Dialog handles confirmation.
        },
        child: Card(
          margin: EdgeInsets.zero,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: session.isPinned
                  ? HermesColors.cyan.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // ─── Status indicator ───
                  if (isActive)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: HermesColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),

                  // ─── Content ───
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row.
                        Row(
                          children: [
                            if (session.isPinned)
                              Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.push_pin,
                                  size: 14,
                                  color: HermesColors.cyan,
                                ),
                              ),
                            if (session.isArchived)
                              Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.archive,
                                  size: 14,
                                  color: HermesColors.warning,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                displayTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        // Subtitle row.
                        Row(
                          children: [
                            if (session.modelName != null) ...[
                              Icon(
                                Icons.smart_toy_outlined,
                                size: 12,
                                color: HermesColors.textDisabled,
                              ),
                              SizedBox(width: 4),
                              Text(
                                session.modelName!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(width: 12),
                            ],
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 12,
                              color: HermesColors.textDisabled,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${session.messageCount}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ─── Right column: time + menu ───
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (session.lastActivity != null)
                        Text(
                          DateFormatter.relativeTime(session.lastActivity!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: HermesColors.textDisabled,
                          ),
                        ),
                      SizedBox(height: 4),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        color: Theme.of(context).colorScheme.surface,
                        icon: Icon(
                          Icons.more_vert,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onSelected: (action) {
                          _handleAction(action, session, ref);
                        },
                        itemBuilder: (_) => [
                          if (!uiState.isOffline) ...[
                            PopupMenuItem(
                              value: 'rename',
                              child: ListTile(
                                leading: Icon(Icons.edit,
                                    size: 18, color: HermesColors.cyan),
                                title: Text('Rename',
                                    style:
                                        TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: session.isPinned ? 'unpin' : 'pin',
                              child: ListTile(
                                leading: Icon(
                                  session.isPinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  size: 18,
                                  color: HermesColors.cyan,
                                ),
                                title: Text(
                                  session.isPinned ? 'Unpin' : 'Pin',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface),
                                ),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: session.isArchived
                                  ? 'unarchive'
                                  : 'archive',
                              child: ListTile(
                                leading: Icon(
                                  session.isArchived
                                      ? Icons.unarchive
                                      : Icons.archive,
                                  size: 18,
                                  color: HermesColors.warning,
                                ),
                                title: Text(
                                  session.isArchived
                                      ? 'Unarchive'
                                      : 'Archive',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface),
                                ),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'fork',
                              child: ListTile(
                                leading: Icon(Icons.call_split,
                                    size: 18, color: HermesColors.info),
                                title: Text('Fork',
                                    style:
                                        TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                          PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete,
                                  size: 18, color: HermesColors.error),
                              title: Text('Delete',
                                  style: TextStyle(color: HermesColors.error)),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleAction(
      String action, SessionSummary session, WidgetRef ref) {
    final notifier = ref.read(sessionsNotifierProvider.notifier);

    switch (action) {
      case 'rename':
        notifier.showRenameDialog(session.id);
      case 'pin':
        notifier.togglePin(session.id, session.isPinned);
      case 'unpin':
        notifier.togglePin(session.id, session.isPinned);
      case 'archive':
        notifier.toggleArchive(session.id, session.isArchived);
      case 'unarchive':
        notifier.toggleArchive(session.id, session.isArchived);
      case 'fork':
        notifier.forkSession(session.id);
      case 'delete':
        notifier.showDeleteConfirmation(session.id);
    }
  }

  /// Truncate title to 80 characters with ellipsis (AC-F003-14).
  static String _truncateTitle(String? title) {
    if (title == null) return 'Untitled';
    if (title.length <= 80) return title;
    return '${title.substring(0, 80)}…';
  }
}
