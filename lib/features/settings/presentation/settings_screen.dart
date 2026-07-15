import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/theme/colors.dart';
import '../../../features/connection/providers/connection_provider.dart';
import '../../../models/server_config.dart';
import '../providers/settings_provider.dart';

/// Settings screen — F-008.
///
/// Sections:
/// - Servers: list configured servers, tap to switch, add new
/// - Appearance: theme mode selector (dark/system/light)
/// - Model: default model input
/// - Profile: current Hermes profile name
/// - Danger Zone: delete all local data, reset to defaults
/// - About: version (0.1.0), licenses, GitHub link
///
/// States handled:
/// - Loading: shown while loading server list
/// - Connected/Disconnected: different server section states
/// - Delete confirmation dialog
///
/// Security: API keys are NEVER displayed — only masked (••••••••).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionProvider);
    final settingsState = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppStrings.settings,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ─── Servers ───
          _buildSectionHeader(AppStrings.server, Icons.dns_outlined, theme),
          SizedBox(height: 12),
          _buildServersSection(context, ref, connectionState, theme),

          SizedBox(height: 24),

          // ─── Appearance ───
          _buildSectionHeader('Appearance', Icons.palette_outlined, theme),
          SizedBox(height: 12),
          _buildAppearanceSection(context, ref, settingsState, theme),

          SizedBox(height: 24),

          // ─── Model ───
          _buildSectionHeader(AppStrings.defaultModel, Icons.smart_toy_outlined, theme),
          SizedBox(height: 12),
          _buildModelSection(context, ref, settingsState, theme),

          SizedBox(height: 24),

          // ─── Profile ───
          _buildSectionHeader('Profile', Icons.person_outline, theme),
          SizedBox(height: 12),
          _buildProfileSection(context, theme, connectionState),

          SizedBox(height: 32),

          // ─── Agent Data ───
          _buildSectionHeader('Agent Data', Icons.dataset_outlined, theme),
          SizedBox(height: 12),
          _buildAgentDataSection(context, theme),

          SizedBox(height: 32),

          // ─── Danger Zone ───
          _buildSectionHeader('Danger Zone', Icons.warning_amber_outlined, theme,
              color: HermesColors.error),
          SizedBox(height: 12),
          _buildDangerZone(context, ref, theme),

          SizedBox(height: 32),

          // ─── About ───
          _buildSectionHeader(AppStrings.about, Icons.info_outline, theme),
          SizedBox(height: 12),
          _buildAboutSection(context, theme),

          SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Section Header ───

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? HermesColors.cyan),
        SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color ?? HermesColors.cyan,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Servers Section ───

  Widget _buildServersSection(BuildContext context, WidgetRef ref,
      ServerConnectionState state, ThemeData theme) {
    if (state.servers.isEmpty) {
      return _buildCard(context,
        child: Column(
          children: [
            Icon(Icons.dns_outlined,              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), size: 32),
            SizedBox(height: 8),
            Text(
              AppStrings.noSavedServers,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push(RoutePaths.connection),
              icon: Icon(Icons.add, size: 18),
              label: Text(AppStrings.addServer),
            ),
          ],
        ),
      );
    }

    return _buildCard(context,
      child: Column(
        children: [
          ...state.servers.map((server) {
            final isActive = state.activeServer?.id == server.id;
            return _ServerTile(
              server: server,
              isActive: isActive,
              onTap: () => _handleServerTap(ref, server, isActive),
            );
          }),
          Divider(color: Theme.of(context).colorScheme.outline, height: 1),
          TextButton.icon(
            onPressed: () => context.push(RoutePaths.servers),
            icon: Icon(Icons.edit_outlined, size: 18),
            label: Text('Manage Servers'),
            style: TextButton.styleFrom(
              foregroundColor: HermesColors.cyan,
            ),
          ),
        ],
      ),
    );
  }

  void _handleServerTap(WidgetRef ref, ServerConfig server, bool isActive) {
    if (isActive) return; // Already active.
    ref.read(connectionProvider.notifier).selectServer(server.id);
  }

  // ─── Appearance Section ───

  Widget _buildAppearanceSection(BuildContext context, WidgetRef ref,
      SettingsState settings, ThemeData theme) {
    return _buildCard(context,
      child: RadioGroup<ThemeModeOption>(
        groupValue: settings.themeMode,
        onChanged: (value) {
          if (value != null) {
            ref.read(settingsProvider.notifier).setThemeMode(value);
          }
        },
        child: Column(
          children: ThemeModeOption.values.map((mode) {
            return RadioListTile<ThemeModeOption>(
              value: mode,
              title: Text(
                mode.displayName,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              activeColor: HermesColors.cyan,
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Model Section ───

  Widget _buildModelSection(BuildContext context, WidgetRef ref,
      SettingsState settings, ThemeData theme) {
    final controller = TextEditingController(text: settings.defaultModel ?? '');

    return _buildCard(context,
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'e.g., deepseek-v4-pro',
          // hintStyle: Inherits from Theme.of(context).inputDecorationTheme.hintStyle
          prefixIcon: Icon(Icons.smart_toy, color: HermesColors.cyan),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: HermesColors.cyan, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onFieldSubmitted: (value) {
          ref.read(settingsProvider.notifier).setDefaultModel(value.trim());
        },
      ),
    );
  }

  // ─── Profile Section ───

  Widget _buildProfileSection(
      BuildContext context, ThemeData theme, ServerConnectionState connectionState) {
    return _buildCard(context,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: HermesColors.cyan.withValues(alpha: 0.2),
          child: Icon(Icons.person, color: HermesColors.cyan),
        ),
        title: Text(
          connectionState.activeServer?.name ?? 'Not connected',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          connectionState.activeServer != null
              ? connectionState.activeServer!.url
              : 'No active server',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ─── Agent Data Section (Skills, Memory, Insights) ───

  Widget _buildAgentDataSection(BuildContext context, ThemeData theme) {
    return _buildCard(context,
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.psychology_outlined,
                color: HermesColors.cyan),
            title: Text(
              AppStrings.skills,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              AppStrings.skillsSubtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () => context.push(RoutePaths.skills),
          ),
          Divider(color: Theme.of(context).colorScheme.outline, height: 1),
          if (FeatureFlags.memoryEnabled) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.memory_outlined,
                  color: HermesColors.cyan),
              title: Text(
                AppStrings.memory,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                AppStrings.memorySubtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () => context.push(RoutePaths.memory),
            ),
            Divider(color: Theme.of(context).colorScheme.outline, height: 1),
          ],
          if (FeatureFlags.insightsEnabled) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.insights_outlined,
                  color: HermesColors.cyan),
              title: Text(
                AppStrings.insights,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                AppStrings.insightsSubtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () => context.push(RoutePaths.insights),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Danger Zone Section ───

  Widget _buildDangerZone(BuildContext context, WidgetRef ref, ThemeData theme) {
    return _buildCard(context,
      borderColor: HermesColors.error.withValues(alpha: 0.3),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, color: HermesColors.cyan),
            title: Text(
              AppStrings.disconnectExit,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: HermesColors.cyan,
              ),
            ),
            subtitle: Text(
              'Return to connection screen. Server configs are kept.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () => _showDisconnectConfirmation(context, ref),
          ),
          Divider(color: Theme.of(context).colorScheme.outline, height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_forever, color: HermesColors.error),
            title: Text(
              'Delete All Local Data',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: HermesColors.error,
              ),
            ),
            subtitle: Text(
              'Remove all servers, preferences, and cached data.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () => _showDeleteConfirmation(context, ref),
          ),
          Divider(color: Theme.of(context).colorScheme.outline, height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.restart_alt, color: HermesColors.warning),
            title: Text(
              'Reset to Defaults',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: HermesColors.warning,
              ),
            ),
            subtitle: Text(
              'Reset preferences without deleting server configs.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () => _showResetConfirmation(context, ref),
          ),
        ],
      ),
    );
  }

  void _showDisconnectConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          AppStrings.settingsDangerZoneDisconnectTitle,
          style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        content: Text(
          AppStrings.settingsDangerZoneDisconnectMessage,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(connectionProvider.notifier).disconnect();
              Navigator.of(ctx).pop();
              // Outer context survives dialog pop — safe to navigate here.
              context.go(RoutePaths.connection);
            },
            style: FilledButton.styleFrom(
              backgroundColor: HermesColors.cyan,
              foregroundColor: HermesColors.dark,
            ),
            child: Text(AppStrings.settingsDangerZoneDisconnectAction),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          AppStrings.settingsDangerZoneDeleteTitle,
          style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        content: Text(
          AppStrings.settingsDangerZoneDeleteMessage,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(settingsProvider.notifier).deleteAllData();
            },
            style: FilledButton.styleFrom(
              backgroundColor: HermesColors.error,
            ),
            child: Text(AppStrings.settingsDangerZoneDeleteAction),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          AppStrings.settingsDangerZoneResetTitle,
          style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        content: Text(
          AppStrings.settingsDangerZoneResetMessage,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(settingsProvider.notifier).setThemeMode(ThemeModeOption.dark);
              ref.read(settingsProvider.notifier).setDefaultModel(null);
              ref.read(settingsProvider.notifier).setDefaultServerId(null);
            },
            style: FilledButton.styleFrom(
              backgroundColor: HermesColors.warning,
              foregroundColor: HermesColors.dark,
            ),
            child: Text(AppStrings.settingsDangerZoneResetAction),
          ),
        ],
      ),
    );
  }

  // ─── About Section ───

  Widget _buildAboutSection(BuildContext context, ThemeData theme) {
    return _buildCard(context,
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline, color: HermesColors.cyan),
            title: Text(
              AppStrings.version,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              '0.1.0 (build 1)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.copy, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '0.1.0'));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Version copied to clipboard')),
                );
              },
            ),
          ),
          Divider(color: Theme.of(context).colorScheme.outline, height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.description_outlined, color: HermesColors.cyan),
            title: Text(
              AppStrings.license,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'MIT License',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () => context.push(RoutePaths.license),
          ),
          Divider(color: Theme.of(context).colorScheme.outline, height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.code, color: HermesColors.cyan.withValues(alpha: 0.7)),
            title: Text(
              'GitHub',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'github.com/jahfaliabdulrahman-dev/hermex_android',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───

  Widget _buildCard(BuildContext context, {required Widget child, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? Theme.of(context).colorScheme.outline,
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

/// A single server tile in the settings server list.
class _ServerTile extends StatelessWidget {
  final ServerConfig server;
  final bool isActive;
  final VoidCallback onTap;

  const _ServerTile({
    required this.server,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isActive ? Icons.check_circle : Icons.circle_outlined,
        color: isActive ? HermesColors.success : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
        size: 22,
      ),
      title: Text(
        server.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        server.url,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isActive
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: HermesColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Active',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: HermesColors.success,
                ),
              ),
            )
          : null,
      onTap: isActive ? null : onTap,
    );
  }
}
