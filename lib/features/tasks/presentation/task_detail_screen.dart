import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/cron_job.dart';
import '../providers/task_provider.dart';

/// Task detail screen — full cron job info with action buttons.
///
/// States handled:
/// - Loading: skeleton/spinner
/// - Success: full job details with actions
/// - Error: error banner with retry
///
/// Actions: Edit, Delete, Pause/Resume, Run Now
///
/// Edge cases:
/// - Delete confirmation dialog
/// - Run Now shows loading indicator
/// - Paused jobs show Resume instead of Pause
/// - Long prompt displayed in full (scrollable)
class TaskDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const TaskDetailScreen({super.key, required this.id});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncJob = ref.watch(taskDetailProvider(widget.id));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: HermesColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppStrings.jobDetails,
          style: theme.textTheme.titleMedium?.copyWith(
            color: HermesColors.textPrimary,
          ),
        ),
        actions: [
          // Edit button
          if (asyncJob.hasValue && asyncJob.value != null)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: HermesColors.cyan),
              tooltip: AppStrings.editJob,
              onPressed: () => _navigateToEdit(widget.id),
            ),
        ],
      ),
      body: asyncJob.when(
        data: (job) => _buildContent(job, theme),
        loading: () => _buildLoadingSkeleton(theme),
        error: (error, _) => _buildErrorState(error, theme),
      ),
    );
  }

  void _navigateToEdit(String id) {
    context.push('${RoutePaths.tasks}/$id/edit');
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HermesColors.surface,
        title: Text(
          AppStrings.deleteJob,
          style: TextStyle(color: HermesColors.textPrimary),
        ),
        content: Text(
          AppStrings.deleteJobConfirm,
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
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: HermesColors.error,
            ),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await ref.read(taskListProvider.notifier).deleteJob(widget.id);
      if (success && mounted) {
        context.pop();
      }
    }
  }

  Future<void> _handleRunNow() async {
    final success =
        await ref.read(taskListProvider.notifier).runJobNow(widget.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job triggered successfully.'),
          backgroundColor: HermesColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Refresh the detail view.
      ref.invalidate(taskDetailProvider(widget.id));
    }
  }

  Future<void> _handleTogglePause(CronJob job) async {
    if (job.paused) {
      await ref.read(taskListProvider.notifier).resumeJob(widget.id);
    } else {
      await ref.read(taskListProvider.notifier).pauseJob(widget.id);
    }
    // Refresh the detail view.
    ref.invalidate(taskDetailProvider(widget.id));
  }

  // ─── Content ───

  Widget _buildContent(CronJob? job, ThemeData theme) {
    if (job == null) {
      return _buildNotFound(theme);
    }

    final listState = ref.watch(taskListProvider);
    final isRunNow = listState.isRunNow && listState.busyJobId == widget.id;
    final isActionBusy = listState.busyJobId == widget.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Name + Status ───
          _buildHeader(job, theme),

          const SizedBox(height: 24),

          // ─── Prompt Section ───
          _buildSection(
            theme: theme,
            icon: Icons.article_outlined,
            title: AppStrings.prompt,
            child: _buildPromptSection(job, theme),
          ),

          const SizedBox(height: 16),

          // ─── Schedule Section ───
          _buildSection(
            theme: theme,
            icon: Icons.schedule,
            title: AppStrings.schedule,
            child: _buildScheduleSection(job, theme),
          ),

          const SizedBox(height: 16),

          // ─── Run History Section ───
          _buildSection(
            theme: theme,
            icon: Icons.history,
            title: AppStrings.runHistory,
            child: _buildRunHistorySection(job, theme),
          ),

          // ─── Model / Skills Section (if present) ───
          if (job.modelName != null || job.skills.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              theme: theme,
              icon: Icons.tune,
              title: 'Configuration',
              child: _buildConfigSection(job, theme),
            ),
          ],

          // ─── Deliver target (if present) ───
          if (job.deliver != null && job.deliver!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              theme: theme,
              icon: Icons.send_outlined,
              title: AppStrings.deliverTarget,
              child: _buildDeliverSection(job, theme),
            ),
          ],

          // ─── Last Error (if present) ───
          if (job.lastError != null && job.lastError!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildErrorSection(job, theme),
          ],

          const SizedBox(height: 32),

          // ─── Action Buttons ───
          _buildActionButtons(job, theme, isRunNow, isActionBusy),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeader(CronJob job, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.name ?? 'Untitled Job',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: HermesColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (job.createdAt != null)
                Text(
                  'Created ${DateFormatter.relativeTime(job.createdAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: HermesColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        _buildStatusChip(job),
      ],
    );
  }

  Widget _buildStatusChip(CronJob job) {
    Color color;
    String label;

    if (job.paused) {
      color = HermesColors.warning;
      label = 'Paused';
    } else {
      final status = job.status?.toLowerCase() ?? 'active';
      switch (status) {
        case 'active':
        case 'running':
          color = HermesColors.success;
          label = 'Active';
          break;
        case 'error':
        case 'failed':
          color = HermesColors.error;
          label = 'Error';
          break;
        default:
          color = HermesColors.info;
          label = status[0].toUpperCase() + status.substring(1);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  // ─── Prompt ───

  Widget _buildPromptSection(CronJob job, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HermesColors.border),
      ),
      child: SelectableText(
        job.prompt,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: HermesColors.textPrimary,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),
    );
  }

  // ─── Schedule ───

  Widget _buildScheduleSection(CronJob job, ThemeData theme) {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.repeat,
          label: 'Cron Expression',
          value: job.schedule,
          theme: theme,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.translate,
          label: 'Description',
          value: DateFormatter.scheduleDescription(job.schedule),
          theme: theme,
        ),
        if (!job.paused && job.nextRun != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.arrow_forward,
            label: 'Next Run',
            value: DateFormatter.dateAndTime(job.nextRun!),
            theme: theme,
          ),
        ],
      ],
    );
  }

  // ─── Run History ───

  Widget _buildRunHistorySection(CronJob job, ThemeData theme) {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.history,
          label: 'Last Run',
          value: job.lastRun != null
              ? DateFormatter.dateAndTime(job.lastRun!)
              : 'Never',
          theme: theme,
        ),
        if (job.lastRun != null) ...[
          const SizedBox(height: 4),
          _buildInfoRow(
            icon: Icons.timer_outlined,
            label: 'Time Since Last Run',
            value: DateFormatter.timeSince(job.lastRun),
            theme: theme,
          ),
        ],
      ],
    );
  }

  // ─── Config ───

  Widget _buildConfigSection(CronJob job, ThemeData theme) {
    return Column(
      children: [
        if (job.modelName != null)
          _buildInfoRow(
            icon: Icons.smart_toy_outlined,
            label: 'Model',
            value: job.modelName!,
            theme: theme,
          ),
        if (job.modelProvider != null) ...[
          const SizedBox(height: 4),
          _buildInfoRow(
            icon: Icons.cloud_outlined,
            label: 'Provider',
            value: job.modelProvider!,
            theme: theme,
          ),
        ],
        if (job.skills.isNotEmpty) ...[
          if (job.modelName != null || job.modelProvider != null)
            const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.extension_outlined,
            label: 'Skills',
            value: job.skills.join(', '),
            theme: theme,
          ),
        ],
      ],
    );
  }

  // ─── Deliver ───

  Widget _buildDeliverSection(CronJob job, ThemeData theme) {
    return _buildInfoRow(
      icon: Icons.send_outlined,
      label: 'Deliver To',
      value: job.deliver ?? '—',
      theme: theme,
    );
  }

  // ─── Error ───

  Widget _buildErrorSection(CronJob job, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HermesColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HermesColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: HermesColors.error),
              const SizedBox(width: 8),
              Text(
                'Last Error',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: HermesColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            job.lastError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: HermesColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info Row Helper ───

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: HermesColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: HermesColors.textDisabled,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: HermesColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Section Builder ───

  Widget _buildSection({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: HermesColors.cyan),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: HermesColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  // ─── Action Buttons ───

  Widget _buildActionButtons(
    CronJob job,
    ThemeData theme,
    bool isRunNow,
    bool isActionBusy,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Run Now
        FilledButton.icon(
          onPressed: isActionBusy ? null : () => _handleRunNow(),
          icon: isRunNow
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: HermesColors.dark,
                  ),
                )
              : const Icon(Icons.play_arrow),
          label: Text(isRunNow ? 'Running...' : AppStrings.runNow),
          style: FilledButton.styleFrom(
            backgroundColor: HermesColors.success,
            foregroundColor: HermesColors.dark,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),

        const SizedBox(height: 12),

        // Pause / Resume
        OutlinedButton.icon(
          onPressed: isActionBusy ? null : () => _handleTogglePause(job),
          icon: Icon(job.paused ? Icons.play_arrow : Icons.pause),
          label: Text(job.paused ? AppStrings.resume : AppStrings.pause),
          style: OutlinedButton.styleFrom(
            foregroundColor: HermesColors.warning,
            side: BorderSide(color: HermesColors.warning),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),

        const SizedBox(height: 12),

        // Delete (destructive)
        OutlinedButton.icon(
          onPressed: isActionBusy ? null : _handleDelete,
          icon: const Icon(Icons.delete_outline),
          label: Text(AppStrings.deleteJob),
          style: OutlinedButton.styleFrom(
            foregroundColor: HermesColors.error,
            side: BorderSide(color: HermesColors.error.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  // ─── Loading ───

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return const Center(
      child: CircularProgressIndicator(color: HermesColors.cyan),
    );
  }

  // ─── Error ───

  Widget _buildErrorState(Object error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: HermesColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.jobNotFound,
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
            OutlinedButton.icon(
              onPressed: () =>
                  ref.invalidate(taskDetailProvider(widget.id)),
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(AppStrings.retry),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                AppStrings.goBack,
                style: TextStyle(color: HermesColors.cyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Not Found ───

  Widget _buildNotFound(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: HermesColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.jobNotFound,
              style: theme.textTheme.titleMedium?.copyWith(
                color: HermesColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                AppStrings.goBack,
                style: TextStyle(color: HermesColors.cyan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
