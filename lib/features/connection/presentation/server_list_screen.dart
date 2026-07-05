import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/colors.dart';
import '../../../models/server_config.dart';
import '../providers/connection_provider.dart';

/// Lists all saved server configurations.
///
/// States handled:
/// - Empty: "No servers configured yet" with onboarding text
/// - Loaded: list of server cards with tap-to-select
/// - Loading: while refreshing
///
/// Edge cases handled:
/// - Swipe to delete with confirmation dialog
/// - Visual indicator for active server
/// - Server name fallback from URL
class ServerListScreen extends ConsumerWidget {
  const ServerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: HermesColors.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppStrings.savedServers,
          style: theme.textTheme.titleLarge?.copyWith(
            color: HermesColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(context, ref, state, theme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ServerConnectionState state,
    ThemeData theme,
  ) {
    // Loading state.
    if (state.isBusy) {
      return const Center(
        child: CircularProgressIndicator(color: HermesColors.cyan),
      );
    }

    // Empty state.
    if (state.servers.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    // Server list.
    return RefreshIndicator(
      color: HermesColors.cyan,
      onRefresh: () => ref.read(connectionProvider.notifier).refreshServers(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: state.servers.length,
        itemBuilder: (context, index) {
          final server = state.servers[index];
          final isActive = server.id == state.activeServer?.id;

          return Dismissible(
            key: ValueKey(server.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) => _confirmDelete(context, ref, server, theme),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: HermesColors.error.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            child: _ServerCard(
              server: server,
              isActive: isActive,
              onTap: () => _handleSelectServer(context, ref, server),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dns_outlined,
              size: 72,
              color: HermesColors.textDisabled,
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.noSavedServers,
              style: theme.textTheme.titleMedium?.copyWith(
                color: HermesColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.addYourFirstServer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: HermesColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.add),
              label: Text(AppStrings.addServer),
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

  // ─── Actions ───

  Future<void> _handleSelectServer(
    BuildContext context,
    WidgetRef ref,
    ServerConfig server,
  ) async {
    await ref.read(connectionProvider.notifier).selectServer(server.id);
    if (context.mounted) {
      Navigator.of(context).pop(); // Return to connection screen.
    }
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ServerConfig server,
    ThemeData theme,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HermesColors.surface,
        title: Text(
          'Delete ${server.name}?',
          style: TextStyle(color: HermesColors.textPrimary),
        ),
        content: Text(
          'This will remove the server configuration and its API key. '
          'This action cannot be undone.',
          style: TextStyle(color: HermesColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppStrings.cancel,
              style: TextStyle(color: HermesColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppStrings.delete,
              style: TextStyle(color: HermesColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(connectionProvider.notifier).deleteServer(server.id);
      return true;
    }
    return false;
  }
}

/// Card widget for a single server configuration.
class _ServerCard extends StatelessWidget {
  final ServerConfig server;
  final bool isActive;
  final VoidCallback onTap;

  const _ServerCard({
    required this.server,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isActive
          ? HermesColors.cyan.withValues(alpha: 0.1)
          : HermesColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? HermesColors.cyan : HermesColors.border,
          width: isActive ? 1.5 : 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Server icon.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? HermesColors.cyan.withValues(alpha: 0.2)
                      : HermesColors.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isActive ? Icons.check_circle : Icons.dns_outlined,
                  color: isActive ? HermesColors.cyan : HermesColors.textSecondary,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              // Server info.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: HermesColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      server.url,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: HermesColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (server.lastConnected != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatLastConnected(server.lastConnected!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: HermesColors.textDisabled,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Active indicator or swipe hint.
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: HermesColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    AppStrings.connected,
                    style: TextStyle(
                      color: HermesColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: HermesColors.textDisabled,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastConnected(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
