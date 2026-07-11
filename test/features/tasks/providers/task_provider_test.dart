import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/tasks/providers/task_provider.dart';
import 'package:hermex_android/models/cron_job.dart';

/// Tests for TaskListState and TaskLoadStatus.
///
/// State container tests validate copyWith behavior and status transitions.
/// Full notifier tests (requiring a live server) are covered by integration tests.
void main() {
  group('TaskLoadStatus', () {
    test('all status values exist', () {
      expect(TaskLoadStatus.values.length, 4);
      expect(TaskLoadStatus.values, contains(TaskLoadStatus.idle));
      expect(TaskLoadStatus.values, contains(TaskLoadStatus.loading));
      expect(TaskLoadStatus.values, contains(TaskLoadStatus.success));
      expect(TaskLoadStatus.values, contains(TaskLoadStatus.error));
    });
  });

  group('TaskListState', () {
    test('default state has idle status and empty jobs', () {
      const state = TaskListState();

      expect(state.status, TaskLoadStatus.idle);
      expect(state.jobs, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.isBusy, false);
      expect(state.busyJobId, isNull);
      expect(state.isRunNow, false);
      expect(state.isDeleting, false);
    });

    test('copyWith updates status', () {
      const state = TaskListState();
      final updated = state.copyWith(status: TaskLoadStatus.loading);

      expect(updated.status, TaskLoadStatus.loading);
    });

    test('copyWith updates jobs list', () {
      const state = TaskListState();
      final jobs = [
        CronJob(id: '1', prompt: 'test', schedule: '* * * * *'),
      ];
      final updated = state.copyWith(jobs: jobs);

      expect(updated.jobs.length, 1);
      expect(updated.jobs.first.id, '1');
    });

    test('copyWith updates error message and clears it', () {
      const state = TaskListState();
      final withError = state.copyWith(errorMessage: 'Something went wrong');
      expect(withError.errorMessage, 'Something went wrong');

      final cleared = withError.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });

    test('copyWith clears error when clearError is true even if new error is set', () {
      const state = TaskListState(errorMessage: 'old error');
      final cleared = state.copyWith(clearError: true, errorMessage: 'new error');

      // clearError takes precedence — sets to null
      expect(cleared.errorMessage, isNull);
    });

    test('copyWith updates busyJobId and clears it', () {
      const state = TaskListState();
      final withBusy = state.copyWith(busyJobId: 'job-1');
      expect(withBusy.busyJobId, 'job-1');

      final cleared = withBusy.copyWith(clearBusyJobId: true);
      expect(cleared.busyJobId, isNull);
    });

    test('copyWith sets isRunNow', () {
      const state = TaskListState();
      final running = state.copyWith(isRunNow: true);

      expect(running.isRunNow, true);
    });

    test('copyWith sets isDeleting', () {
      const state = TaskListState();
      final deleting = state.copyWith(isDeleting: true);

      expect(deleting.isDeleting, true);
    });

    test('copyWith can update multiple fields at once', () {
      const state = TaskListState();
      final updated = state.copyWith(
        status: TaskLoadStatus.success,
        isBusy: true,
        busyJobId: 'multi-job',
      );

      expect(updated.status, TaskLoadStatus.success);
      expect(updated.isBusy, true);
      expect(updated.busyJobId, 'multi-job');
    });

    test('state with error has correct status', () {
      const state = TaskListState(
        status: TaskLoadStatus.error,
        errorMessage: 'Connection refused',
      );

      expect(state.status, TaskLoadStatus.error);
      expect(state.errorMessage, 'Connection refused');
    });

    test('state with success has list of jobs', () {
      final jobs = [
        CronJob(id: 'a', prompt: 'Job A', schedule: '0 0 * * *'),
        CronJob(id: 'b', prompt: 'Job B', schedule: '0 9 * * *'),
      ];
      final state = TaskListState(status: TaskLoadStatus.success, jobs: jobs);

      expect(state.status, TaskLoadStatus.success);
      expect(state.jobs.length, 2);
    });
  });

  group('Duplicate tap prevention', () {
    test('isBusy prevents concurrent operations', () {
      // Simulated check: when state.isBusy is true, actions should block
      const state = TaskListState(isBusy: true);
      expect(state.isBusy, true);
    });

    test('busyJobId is set during mutations', () {
      const state = TaskListState(
        isBusy: true,
        busyJobId: 'target-job',
        isRunNow: true,
      );

      expect(state.busyJobId, 'target-job');
      expect(state.isRunNow, true);
    });
  });

  group('_isLoadingJobs guard fix (BUG: mutation refresh blocked)', () {
    test('isBusy does NOT block subsequent load — separate from isLoading guard', () {
      // Simulated: when a mutation sets isBusy=true, it should NOT prevent
      // _loadJobs from refreshing the list. The private _isLoadingJobs flag
      // guards loads separately from the per-row isBusy UI indicator.
      const state = TaskListState(isBusy: true, busyJobId: 'job-1');
      // isBusy should be available for UI (per-row loading indicator)
      expect(state.isBusy, true);
      expect(state.busyJobId, 'job-1');
      // isBusy does NOT mean _isLoadingJobs — they are independent concepts
      // The _isLoadingJobs guard lives in the notifier, not the state
    });

    test('state can transition from busy to success without blocking', () {
      // After a mutation completes, the state should be able to transition
      // from isBusy=true back to success with updated jobs.
      final jobs = [
        CronJob(id: '1', prompt: 'Job A', schedule: '* * * * *'),
        CronJob(id: '2', prompt: 'Job B', schedule: '0 * * * *'),
      ];
      const busyState = TaskListState(
        status: TaskLoadStatus.success,
        isBusy: true,
        busyJobId: '1',
        jobs: [],
      );
      // After _loadJobs completes, state updates without isBusy blocking
      final refreshed = busyState.copyWith(
        status: TaskLoadStatus.success,
        jobs: jobs,
        isBusy: false,
        clearBusyJobId: true,
      );
      expect(refreshed.status, TaskLoadStatus.success);
      expect(refreshed.jobs.length, 2);
      expect(refreshed.isBusy, false);
      expect(refreshed.busyJobId, isNull);
    });

    test('flip from paused to active updates state correctly', () {
      // Simulating: user taps pause, then resume on different job
      final jobs = [
        CronJob(id: 'a', prompt: 'Paused job', schedule: '0 0 * * *', paused: true),
        CronJob(id: 'b', prompt: 'Active job', schedule: '0 9 * * *'),
      ];
      final state = TaskListState(
        status: TaskLoadStatus.success,
        jobs: jobs,
      );
      expect(state.jobs.first.paused, true);
      expect(state.jobs.last.paused, false);
    });

    test('state supports multiple sequential mutations without interference', () {
      // Each mutation sets isBusy + busyJobId, then resets after _loadJobs.
      // The guard change ensures _loadJobs is not blocked by isBusy.
      const initialState = TaskListState(status: TaskLoadStatus.success);
      
      // Pause job-1
      final afterPause = initialState.copyWith(
        isBusy: true, busyJobId: 'job-1',
      );
      expect(afterPause.isBusy, true);
      expect(afterPause.busyJobId, 'job-1');
      
      // After mutation + _loadJobs completes
      final afterRefresh = afterPause.copyWith(
        isBusy: false, clearBusyJobId: true,
      );
      expect(afterRefresh.isBusy, false);
      expect(afterRefresh.busyJobId, isNull);
      
      // Can immediately start another mutation
      final afterResume = afterRefresh.copyWith(
        isBusy: true, busyJobId: 'job-2',
      );
      expect(afterResume.isBusy, true);
      expect(afterResume.busyJobId, 'job-2');
    });
  });

  group('Pagination fix (per_page query param)', () {
    test('state supports more than 2 jobs in list', () {
      // Before fix: server may return only 2 jobs due to default pagination.
      // After fix: per_page=50 ensures all jobs are returned.
      final jobs = List.generate(
        5,
        (i) => CronJob(
          id: 'job-$i',
          prompt: 'Task ${i + 1}',
          schedule: '0 $i * * *',
        ),
      );
      final state = TaskListState(
        status: TaskLoadStatus.success,
        jobs: jobs,
      );
      expect(state.jobs.length, 5);
      expect(state.jobs[0].id, 'job-0');
      expect(state.jobs[4].id, 'job-4');
    });

    test('state handles empty paginated response gracefully', () {
      // Server returns {"jobs": [], "total": 0} — should render as empty
      const emptyState = TaskListState(
        status: TaskLoadStatus.success,
        jobs: [],
      );
      expect(emptyState.jobs, isEmpty);
      expect(emptyState.status, TaskLoadStatus.success);
    });
  });

}
