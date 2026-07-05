import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/tasks/presentation/task_list_screen.dart';
import 'package:hermex_android/models/cron_job.dart';
import 'package:hermex_android/core/constants/app_strings.dart';

/// Wraps a widget in ProviderScope and MaterialApp for testing.
Widget testableWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('TaskListScreen — rendering', () {
    testWidgets('renders AppBar with cron jobs title', (tester) async {
      await tester.pumpWidget(testableWidget(const TaskListScreen()));

      // "Cron Jobs" appears both in the AppBar title and in the idle state body text.
      expect(find.text(AppStrings.cronJobs), findsWidgets);
    });

    testWidgets('renders FAB with create job label', (tester) async {
      await tester.pumpWidget(testableWidget(const TaskListScreen()));

      expect(find.text(AppStrings.createJob), findsOneWidget);
    });

    testWidgets('renders idle state icon and text', (tester) async {
      await tester.pumpWidget(testableWidget(const TaskListScreen()));

      // In idle state, shows schedule icon
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    });
  });

  group('CronJob model — status display', () {
    test('active status returns correct value', () {
      final job = CronJob(
        id: '1',
        prompt: 'test',
        schedule: '* * * * *',
        status: 'active',
        paused: false,
      );
      expect(job.status, 'active');
      expect(job.paused, false);
    });

    test('paused status has paused flag', () {
      final job = CronJob(
        id: '1',
        prompt: 'test',
        schedule: '* * * * *',
        paused: true,
      );
      expect(job.paused, true);
    });

    test('error status is reflected', () {
      final job = CronJob(
        id: '1',
        prompt: 'test',
        schedule: '* * * * *',
        status: 'error',
      );
      expect(job.status, 'error');
    });
  });

  group('CronJob model — fields', () {
    test('contains all relevant fields for display', () {
      final job = CronJob(
        id: 'job-1',
        prompt: 'Run daily report',
        schedule: '0 9 * * *',
        name: 'Daily Report',
        status: 'active',
        paused: false,
        lastRun: DateTime(2026, 7, 5, 9, 0),
        nextRun: DateTime(2026, 7, 6, 9, 0),
        skills: ['a', 'b'],
        modelName: 'gpt-4',
        modelProvider: 'openai',
        deliver: 'telegram',
        lastError: null,
      );

      expect(job.name, 'Daily Report');
      expect(job.prompt, 'Run daily report');
      expect(job.schedule, '0 9 * * *');
      expect(job.lastRun, isNotNull);
      expect(job.nextRun, isNotNull);
      expect(job.skills, ['a', 'b']);
      expect(job.modelName, 'gpt-4');
      expect(job.deliver, 'telegram');
    });
  });
}
