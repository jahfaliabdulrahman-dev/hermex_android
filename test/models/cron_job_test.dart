import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/models/cron_job.dart';

void main() {
  group('CronJob — fromJson', () {
    test('parses a complete cron job', () {
      final json = {
        'id': 'job-123',
        'prompt': 'Summarize today news',
        'schedule': '0 9 * * *',
        'status': 'active',
        'last_run': 1700000000,
        'next_run': 1700086400,
        'skills': ['news-summarizer', 'translation'],
        'model_provider': 'deepseek',
        'model_name': 'deepseek-v4-pro',
        'name': 'Daily News',
        'deliver': 'telegram',
        'created_at': 1699900000,
        'last_error': null,
        'paused': false,
      };

      final job = CronJob.fromJson(json);

      expect(job.id, 'job-123');
      expect(job.prompt, 'Summarize today news');
      expect(job.schedule, '0 9 * * *');
      expect(job.status, 'active');
      expect(job.lastRun, DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000));
      expect(job.nextRun, DateTime.fromMillisecondsSinceEpoch(1700086400 * 1000));
      expect(job.skills, ['news-summarizer', 'translation']);
      expect(job.modelProvider, 'deepseek');
      expect(job.modelName, 'deepseek-v4-pro');
      expect(job.name, 'Daily News');
      expect(job.deliver, 'telegram');
      expect(job.paused, false);
    });

    test('parses string timestamps', () {
      final json = {
        'id': 'job-1',
        'prompt': 'Test',
        'schedule': '* * * * *',
        'last_run': '2026-07-05T09:00:00Z',
        'next_run': '2026-07-06T09:00:00Z',
      };

      final job = CronJob.fromJson(json);

      expect(job.lastRun, DateTime.parse('2026-07-05T09:00:00Z'));
      expect(job.nextRun, DateTime.parse('2026-07-06T09:00:00Z'));
    });

    test('defaults missing fields', () {
      final json = {
        'id': 'job-1',
        'prompt': 'Test',
        'schedule': '* * * * *',
      };

      final job = CronJob.fromJson(json);

      expect(job.status, isNull);
      expect(job.lastRun, isNull);
      expect(job.nextRun, isNull);
      expect(job.skills, isEmpty);
      expect(job.modelProvider, isNull);
      expect(job.modelName, isNull);
      expect(job.name, isNull);
      expect(job.deliver, isNull);
      expect(job.paused, false);
      expect(job.lastError, isNull);
    });

    test('handles null timestamps', () {
      final json = {
        'id': 'job-1',
        'prompt': 'Test',
        'schedule': '* * * * *',
        'last_run': null,
        'next_run': null,
      };

      final job = CronJob.fromJson(json);

      expect(job.lastRun, isNull);
      expect(job.nextRun, isNull);
    });

    test('handles malformed date gracefully', () {
      final json = {
        'id': 'job-1',
        'prompt': 'Test',
        'schedule': '* * * * *',
        'last_run': 'not-a-date',
      };

      final job = CronJob.fromJson(json);

      expect(job.lastRun, isNull);
    });
  });

  group('CronJob — equality', () {
    test('two jobs with same fields are equal', () {
      final a = CronJob(id: 'job-1', prompt: 'Test', schedule: '* * * * *');
      final b = CronJob(id: 'job-1', prompt: 'Test', schedule: '* * * * *');
      expect(a, equals(b));
    });

    test('two jobs with different id are not equal', () {
      final a = CronJob(id: 'job-1', prompt: 'Test', schedule: '* * * * *');
      final b = CronJob(id: 'job-2', prompt: 'Test', schedule: '* * * * *');
      expect(a, isNot(equals(b)));
    });
  });
}
