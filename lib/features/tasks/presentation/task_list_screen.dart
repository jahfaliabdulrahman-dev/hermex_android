import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/cron_job.dart';
import '../providers/task_provider.dart';

/// Task list screen — displays all cron jobs with status indicators.
///
/// States handled:
/// - Idle: initial state, no data yet
/// - Loading: shimmer/skeleton placeholders
/// - Success: list of job cards
/// - Empty: CTA to create first job
/// - Error: error banner with retry
///
/// Edge cases handled:
/// - Pull-to-refresh
/// - Long prompt truncation
/// - Schedule display in human-readable format
/// - Status badges (active, paused, error)
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger load after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskListProvider.notifier).refreshJobs();
    });
  }

  // ─── Navigation ───

  void _navigateToDetail(String id) {
    context.push(RoutePaths.taskById(id));
  }

  void _navigateToCreate() {
    context.push('${RoutePaths.tasks}/new');
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppStrings.cronJobs,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: HermesColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(state, theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.createJob),
        backgroundColor: HermesColors.cyan,
        foregroundColor: HermesColors.dark,
      ),
    );
  }

  Widget _buildBody(TaskListState state, ThemeData theme) {
    switch (state.status) {
      case TaskLoadStatus.idle:
        return _buildIdleState(theme);
      case TaskLoadStatus.loading:
        return _buildLoadingSkeleton(theme);
      case TaskLoadStatus.error:
        return _buildErrorState(state, theme);
      case TaskLoadStatus.success:
        if (state.jobs.isEmpty) {
          return _buildEmptyState(theme);
        }
        return _buildJobList(state, theme);
    }
  }

  // ─── Idle ───

  Widget _buildIdleState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 64,
            color: HermesColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.cronJobs,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: HermesColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading ───

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => _JobCardSkeleton(),
    );
  }

  // ─── Error ───

  Widget _buildErrorState(TaskListState state, ThemeData theme) {
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
              AppStrings.failedToLoadJobs,
              style: theme.textTheme.titleMedium?.copyWith(
                color: HermesColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: HermesColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => ref.read(taskListProvider.notifier).refreshJobs(),
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty ───

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_send,
              size: 80,
              color: HermesColors.cyan.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noCronJobs,
              style: theme.textTheme.titleMedium?.copyWith(
                color: HermesColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.createFirstCronJob,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: HermesColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Job List ───

  Widget _buildJobList(TaskListState state, ThemeData theme) {
    return RefreshIndicator(
      color: HermesColors.cyan,
      backgroundColor: HermesColors.surface,
      onRefresh: () => ref.read(taskListProvider.notifier).refreshJobs(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.jobs.length,
        itemBuilder: (context, index) {
          final job = state.jobs[index];
          final isBusy = state.busyJobId == job.id;
          return _JobCard(
            job: job,
            isBusy: isBusy,
            isRunNow: state.isRunNow && isBusy,
            isDeleting: state.isDeleting && isBusy,
            onTap: () => _navigateToDetail(job.id),
            onRunNow: () => ref.read(taskListProvider.notifier).runJobNow(job.id),
            onTogglePause: () {
              if (job.paused) {
                ref.read(taskListProvider.notifier).resumeJob(job.id);
              } else {
                ref.read(taskListProvider.notifier).pauseJob(job.id);
              }
            },
            onDelete: () => _confirmDelete(job),
          );
        },
      ),
    );
  }

  /// Show delete confirmation dialog.
  Future<void> _confirmDelete(CronJob job) async {
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
      ref.read(taskListProvider.notifier).deleteJob(job.id);
    }
  }
}

// ─── Job Card ───

class _JobCard extends StatelessWidget {
  final CronJob job;
  final bool isBusy;
  final bool isRunNow;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onRunNow;
  final VoidCallback onTogglePause;
  final VoidCallback onDelete;

  const _JobCard({
    required this.job,
    required this.isBusy,
    required this.isRunNow,
    required this.isDeleting,
    required this.onTap,
    required this.onRunNow,
    required this.onTogglePause,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Row 1: Name + Status Badge ───
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.name ?? job.prompt,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: HermesColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(job: job),
                ],
              ),

              // ─── Row 2: Prompt preview (if name is set) ───
              if (job.name != null && job.name!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  job.prompt,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: HermesColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // ─── Row 3: Schedule + Last Run ───
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: HermesColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.scheduleDescription(job.schedule),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: HermesColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (job.lastRun != null) ...[
                    Icon(
                      Icons.history,
                      size: 14,
                      color: HermesColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.timeSince(job.lastRun),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: HermesColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // ─── Row 4: Next Run ───
              if (job.nextRun != null && !job.paused)
                Row(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: HermesColors.textDisabled,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.nextRunLabel(job.nextRun),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: HermesColors.textDisabled,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // ─── Row 5: Action Buttons ───
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isBusy && isRunNow)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: HermesColors.cyan,
                      ),
                    )
                  else ...[
                    _ActionChip(
                      icon: Icons.play_arrow,
                      label: AppStrings.runNow,
                      color: HermesColors.success,
                      onTap: isBusy ? null : onRunNow,
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      icon: job.paused ? Icons.play_arrow : Icons.pause,
                      label: job.paused ? AppStrings.resume : AppStrings.pause,
                      color: HermesColors.warning,
                      onTap: isBusy ? null : onTogglePause,
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      icon: Icons.delete_outline,
                      color: HermesColors.error,
                      onTap: isBusy ? null : onDelete,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ───

class _StatusBadge extends StatelessWidget {
  final CronJob job;

  const _StatusBadge({required this.job});

  @override
  Widget build(BuildContext context) {
    final (label, color, dotColor) = _statusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _statusInfo() {
    if (job.paused) {
      return ('Paused', HermesColors.warning, HermesColors.warning);
    }

    final status = job.status?.toLowerCase() ?? 'active';

    switch (status) {
      case 'active':
      case 'running':
        return ('Active', HermesColors.success, HermesColors.success);
      case 'error':
      case 'failed':
        return ('Error', HermesColors.error, HermesColors.error);
      case 'paused':
        return ('Paused', HermesColors.warning, HermesColors.warning);
      case 'completed':
        return ('Done', HermesColors.info, HermesColors.info);
      default:
        return ('Idle', HermesColors.textSecondary, HermesColors.textSecondary);
    }
  }
}

// ─── Action Chip ───

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = label != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label!, style: TextStyle(fontSize: 11, color: color)),
            ],
          )
        : Icon(icon, size: 16, color: color);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: child,
      ),
    );
  }
}

// ─── Skeleton Placeholder ───

class _JobCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title shimmer
            Container(
              height: 16,
              width: 200,
              decoration: BoxDecoration(
                color: HermesColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle shimmer
            Container(
              height: 12,
              width: 150,
              decoration: BoxDecoration(
                color: HermesColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            // Actions shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: HermesColors.border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
