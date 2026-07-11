import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/colors.dart';
import '../../../models/insights_data.dart';
import '../providers/insights_provider.dart';

/// Usage insights and statistics dashboard.
///
/// States handled:
/// - Loading: spinner
/// - Empty/Zero: "No insights available yet"
/// - Error: error banner with retry
/// - Success: stat cards grid
///
/// Displays:
/// - Total sessions, messages, tokens, active time
/// - Cron jobs run, skills count
/// - Last synced timestamp
class InsightsScreen extends ConsumerWidget {
 const InsightsScreen({super.key});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
 final insightsAsync = ref.watch(insightsProvider);
 final theme = Theme.of(context);

 return Scaffold(
 backgroundColor: Theme.of(context).scaffoldBackgroundColor,
 appBar: AppBar(
 backgroundColor: Colors.transparent,
 elevation: 0,
 title: Text(
 AppStrings.insights,
 style: theme.textTheme.headlineSmall?.copyWith(
 color: Theme.of(context).colorScheme.onSurface,
 fontWeight: FontWeight.bold,
 ),
 ),
 centerTitle: false,
 leading: IconButton(
 icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
 onPressed: () => Navigator.of(context).pop(),
 ),
 ),
 body: insightsAsync.when(
 loading: () => const Center(
 child: CircularProgressIndicator(color: HermesColors.cyan),
 ),
 error: (error, stack) => _buildErrorState(error.toString(), theme, ref),
 data: (data) => _buildContent(data, theme, ref),
 ),
 );
 }

 Widget _buildContent(InsightsData data, ThemeData theme, WidgetRef ref) {
 // Check if data is essentially empty (all zeros).
 final isEmpty = data.totalSessions == 0 &&
 data.totalMessages == 0 &&
 data.totalTokens == 0;

 if (isEmpty) {
 return _buildEmptyState(theme);
 }

 return RefreshIndicator(
 color: HermesColors.cyan,
 onRefresh: () => ref.refresh(insightsProvider.future),
 child: ListView(
 padding: const EdgeInsets.all(16),
 children: [
 // ─── Primary Stats Grid ───
 _buildSectionHeader(AppStrings.insights, theme),
 const SizedBox(height: 12),
 _buildStatsGrid(data, theme),

 const SizedBox(height: 32),

 // ─── Secondary Stats ───
 _buildSectionHeader('Activity', theme),
 const SizedBox(height: 12),
 _buildSecondaryStats(data, theme),

 // ─── Last Synced ───
 if (data.lastSynced != null) ...[
 const SizedBox(height: 32),
 _buildLastSynced(data, theme),
 ],
 ],
 ),
 );
 }

 // ─── Section Header ───

 Widget _buildSectionHeader(String title, ThemeData theme) {
 return Padding(
 padding: const EdgeInsets.only(bottom: 4),
 child: Text(
 title,
 style: theme.textTheme.titleSmall?.copyWith(
 color: HermesColors.cyan,
 fontWeight: FontWeight.w600,
 ),
 ),
 );
 }

 // ─── Stats Grid ───

 Widget _buildStatsGrid(InsightsData data, ThemeData theme) {
 return GridView.count(
 crossAxisCount: 2,
 shrinkWrap: true,
 physics: const NeverScrollableScrollPhysics(),
 mainAxisSpacing: 12,
 crossAxisSpacing: 12,
 childAspectRatio: 1.3,
 children: [
 _StatCard(
 icon: Icons.forum_outlined,
 label: 'Sessions',
 value: data.totalSessions.toString(),
 color: HermesColors.cyan,
 ),
 _StatCard(
 icon: Icons.message_outlined,
 label: 'Messages',
 value: _formatCount(data.totalMessages),
 color: HermesColors.info,
 ),
 _StatCard(
 icon: Icons.token_outlined,
 label: 'Tokens',
 value: data.formattedTokens,
 color: HermesColors.warning,
 ),
 _StatCard(
 icon: Icons.timer_outlined,
 label: 'Active Time',
 value: data.formattedActiveTime,
 color: HermesColors.success,
 ),
 ],
 );
 }

 Widget _buildSecondaryStats(InsightsData data, ThemeData theme) {
 return Row(
 children: [
 Expanded(
 child: _StatCard(
 icon: Icons.schedule_outlined,
 label: 'Cron Jobs Run',
 value: data.cronJobsRun.toString(),
 color: HermesColors.info,
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: _StatCard(
 icon: Icons.extension_outlined,
 label: 'Skills',
 value: data.skillsCount.toString(),
 color: HermesColors.success,
 ),
 ),
 ],
 );
 }

 Widget _buildLastSynced(InsightsData data, ThemeData theme) {
 return Container(
 padding: EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.surface,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
 ),
 child: Row(
 children: [
 Icon(Icons.sync, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
 SizedBox(width: 8),
 Text(
 '${AppStrings.lastSynced}: ${_formatDateTime(data.lastSynced!)}',
 style: theme.textTheme.labelSmall?.copyWith(
 color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
 ),
 ),
 ],
 ),
 );
 }

 // ─── States ───

 Widget _buildEmptyState(ThemeData theme) {
 return Center(
 child: Padding(
 padding: EdgeInsets.symmetric(horizontal: 32),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 Icons.analytics_outlined,
 size: 64,
 color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
 ),
 SizedBox(height: 16),
 Text(
 AppStrings.noInsightsAvailable,
 style: theme.textTheme.titleMedium?.copyWith(
 color: Theme.of(context).colorScheme.onSurface,
 ),
 textAlign: TextAlign.center,
 ),
 SizedBox(height: 8),
 Text(
 AppStrings.startUsingAgentForData,
 style: theme.textTheme.bodyMedium?.copyWith(
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 textAlign: TextAlign.center,
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildErrorState(String error, ThemeData theme, WidgetRef ref) {
 return Center(
 child: Padding(
 padding: const EdgeInsets.symmetric(horizontal: 32),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 const Icon(
 Icons.error_outline,
 size: 48,
 color: HermesColors.error,
 ),
 const SizedBox(height: 16),
 Text(
 AppStrings.failedToLoadInsights,
 style: theme.textTheme.titleMedium?.copyWith(
 color: HermesColors.error,
 ),
 textAlign: TextAlign.center,
 ),
 SizedBox(height: 8),
 Text(
 error,
 style: theme.textTheme.bodySmall?.copyWith(
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 textAlign: TextAlign.center,
 maxLines: 3,
 overflow: TextOverflow.ellipsis,
 ),
 const SizedBox(height: 24),
 OutlinedButton.icon(
 onPressed: () => ref.invalidate(insightsProvider),
 icon: const Icon(Icons.refresh, size: 18),
 label: Text(AppStrings.retry),
 ),
 ],
 ),
 ),
 );
 }

 // ─── Helpers ───

 String _formatCount(int count) {
 if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
 if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
 return count.toString();
 }

 String _formatDateTime(DateTime dt) {
 return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
 '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
 }
}

/// A single stat card for the insights dashboard.
class _StatCard extends StatelessWidget {
 final IconData icon;
 final String label;
 final String value;
 final Color color;

 const _StatCard({
 required this.icon,
 required this.label,
 required this.value,
 required this.color,
 });

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);

 return Card(
 color: Theme.of(context).colorScheme.surface,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
 ),
 child: Padding(
 padding: const EdgeInsets.all(16),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Icon(icon, color: color, size: 24),
 Spacer(),
 Text(
 value,
 style: theme.textTheme.headlineSmall?.copyWith(
 color: Theme.of(context).colorScheme.onSurface,
 fontWeight: FontWeight.bold,
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 SizedBox(height: 2),
 Text(
 label,
 style: theme.textTheme.labelSmall?.copyWith(
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 );
 }
}
