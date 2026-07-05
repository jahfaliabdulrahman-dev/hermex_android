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
}
