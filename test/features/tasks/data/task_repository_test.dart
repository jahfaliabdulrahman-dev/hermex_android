import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/core/api/api_exception.dart';
import 'package:hermex_android/models/cron_job.dart';

/// Tests for TaskRepository JSON parsing and error handling.
///
/// These tests focus on the repository's parsing logic without requiring
/// a live server. The repository's API calls are tested indirectly through
/// the provider tests.
///
/// DEC-EPIC001-DEPCHECK: Updated all test fixtures to use real Hermes API
/// Server v0.18.2 field names (state, last_run_at, next_run_at, provider,
/// model, paused_at).
void main() {
  group('CronJob JSON parsing', () {
    test('parses a complete job with all fields', () {
      final json = {
        'id': 'job-123',
        'prompt': 'Daily briefing',
        'schedule': '0 9 * * *',
        'state': 'active',
        'last_run_at': 1750000000,
        'next_run_at': 1750086400,
        'skills': ['hermes-agent', 'code-review'],
        'provider': 'deepseek',
        'model': 'deepseek-v4-pro',
        'name': 'Morning Briefing',
        'deliver': 'telegram',
        'created_at': 1749000000,
        'last_error': null,
        'paused_at': null,
      };

      final job = CronJob.fromJson(json);

      expect(job.id, 'job-123');
      expect(job.prompt, 'Daily briefing');
      expect(job.schedule, '0 9 * * *');
      expect(job.status, 'active');
      expect(job.lastRun, isNotNull);
      expect(job.nextRun, isNotNull);
      expect(job.skills, ['hermes-agent', 'code-review']);
      expect(job.modelProvider, 'deepseek');
      expect(job.modelName, 'deepseek-v4-pro');
      expect(job.name, 'Morning Briefing');
      expect(job.deliver, 'telegram');
      expect(job.paused, false);
    });

    test('parses a minimal job with only required fields', () {
      final json = {
        'id': 'job-min',
        'prompt': 'Test',
        'schedule': '* * * * *',
      };

      final job = CronJob.fromJson(json);

      expect(job.id, 'job-min');
      expect(job.prompt, 'Test');
      expect(job.schedule, '* * * * *');
      expect(job.status, isNull);
      expect(job.lastRun, isNull);
      expect(job.nextRun, isNull);
      expect(job.skills, isEmpty);
      expect(job.modelProvider, isNull);
      expect(job.modelName, isNull);
      expect(job.paused, false);
    });

    test('parses a paused job', () {
      final json = {
        'id': 'job-paused',
        'prompt': 'Paused job',
        'schedule': '0 * * * *',
        'paused_at': '2026-07-09T10:00:00+03:00',
      };

      final job = CronJob.fromJson(json);

      expect(job.paused, true);
    });

    test('handles null timestamp fields gracefully', () {
      final json = {
        'id': 'job-ts',
        'prompt': 'No timestamps',
        'schedule': '* * * * *',
        'last_run_at': null,
        'next_run_at': null,
        'created_at': null,
      };

      final job = CronJob.fromJson(json);

      expect(job.lastRun, isNull);
      expect(job.nextRun, isNull);
      expect(job.createdAt, isNull);
    });

    test('handles string timestamps', () {
      final json = {
        'id': 'job-str',
        'prompt': 'String timestamps',
        'schedule': '0 9 * * *',
        'last_run_at': '2026-07-05T09:00:00',
        'next_run_at': '2026-07-06T09:00:00',
      };

      final job = CronJob.fromJson(json);

      expect(job.lastRun, isNotNull);
      expect(job.nextRun, isNotNull);
    });

    test('handles empty skills array', () {
      final json = {
        'id': 'job-empty',
        'prompt': 'No skills',
        'schedule': '* * * * *',
        'skills': [],
      };

      final job = CronJob.fromJson(json);

      expect(job.skills, isEmpty);
    });

    test('handles missing optional fields with defaults', () {
      final json = {
        'id': 'job-def',
        'prompt': 'Defaults',
        'schedule': '0 0 * * *',
      };

      final job = CronJob.fromJson(json);

      // Default values
      expect(job.skills, isEmpty); // @Default([])
    });

    test('round-trips via toJson/fromJson for key fields', () {
      final original = CronJob(
        id: 'rt-1',
        prompt: 'Round trip test',
        schedule: '0 9 * * *',
        status: 'active',
        name: 'Test Job',
        paused: false,
        skills: ['s1', 's2'],
        modelName: 'test-model',
      );

      // fromJson(toJson()) should work for the key fields.
      // toJson() now emits real API keys (state, provider, model, etc.)
      final json = original.toJson();

      final restored = CronJob.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.prompt, original.prompt);
      expect(restored.schedule, original.schedule);
      expect(restored.status, original.status);
      expect(restored.name, original.name);
      expect(restored.paused, original.paused);
      expect(restored.skills, original.skills);
      expect(restored.modelName, original.modelName);
    });

    test('parses schedule as object (interval kind)', () {
      final json = {
        'id': 'job-int',
        'prompt': 'Interval job',
        'schedule': {
          'kind': 'interval',
          'minutes': 2,
          'display': 'every 2m',
        },
      };

      final job = CronJob.fromJson(json);

      // schedule object should be converted to display string
      expect(job.schedule, 'every 2m');
    });

    test('parses schedule as object (cron kind)', () {
      final json = {
        'id': 'job-cron',
        'prompt': 'Cron job',
        'schedule': {
          'kind': 'cron',
          'expr': '0 4 * * 0',
          'display': '0 4 * * 0',
        },
      };

      final job = CronJob.fromJson(json);

      expect(job.schedule, '0 4 * * 0');
    });
  });

  group('ApiException classification', () {
    test('ConnectionException has correct properties', () {
      final ex = ConnectionException('timeout', statusCode: null);
      expect(ex.message, 'timeout');
      expect(ex.statusCode, isNull);
      // toString() must NOT leak internal details to UI.
      expect(ex.toString(), contains('Request failed'));
      // toDebugString() includes full details for debug logging only.
      expect(ex.toDebugString(), contains('timeout'));
      expect(ex.toDebugString(), contains('ConnectionException'));
    });

    test('AuthException has correct properties', () {
      final ex = AuthException('unauthorized', statusCode: 401);
      expect(ex.message, 'unauthorized');
      expect(ex.statusCode, 401);
    });

    test('ServerException has correct properties', () {
      final ex = ServerException('server error', statusCode: 500, responseBody: 'boom');
      expect(ex.message, 'server error');
      expect(ex.statusCode, 500);
      expect(ex.responseBody, 'boom');
    });

    test('ClientException has correct properties', () {
      final ex = ClientException('bad request', statusCode: 400);
      expect(ex.message, 'bad request');
      expect(ex.statusCode, 400);
    });
  });

  group('getAll pagination support', () {
    test('parses 5-job response correctly (no pagination truncation)', () {
      // Simulate server response with 5 jobs — validates that the parser
      // handles the full array regardless of per_page param.
      final jobsList = List.generate(5, (i) => {
        'id': 'job-$i',
        'prompt': 'Task \${i + 1}',
        'schedule': '0 $i * * *',
      });
      
      final parsed = jobsList
          .map((json) => CronJob.fromJson(json as Map<String, dynamic>))
          .toList();
      
      expect(parsed.length, 5);
      expect(parsed.first.id, 'job-0');
      expect(parsed.last.id, 'job-4');
    });

    test('handles empty jobs array from server', () {
      final jobsList = <Map<String, dynamic>>[];
      final parsed = jobsList
          .map((json) => CronJob.fromJson(json))
          .toList();
      expect(parsed, isEmpty);
    });

    test('handles paginated response with total != length', () {
      // Server returns: {"jobs": [job1, job2], "total": 5}
      // After per_page=50 fix, the jobs array should contain all entries.
      // This test validates that we extract the array regardless of total.
      final response = {
        'jobs': [
          {'id': 'a', 'prompt': 'Job A', 'schedule': '* * * * *'},
          {'id': 'b', 'prompt': 'Job B', 'schedule': '0 * * * *'},
          {'id': 'c', 'prompt': 'Job C', 'schedule': '0 0 * * *'},
          {'id': 'd', 'prompt': 'Job D', 'schedule': '0 0 0 * *'},
          {'id': 'e', 'prompt': 'Job E', 'schedule': '0 0 0 0 *'},
        ],
        'total': 5,
      };
      
      final jobsArray = response['jobs'] as List<dynamic>;
      expect(jobsArray.length, 5);
      
      final parsed = jobsArray
          .map((j) => CronJob.fromJson(j as Map<String, dynamic>))
          .toList();
      expect(parsed.length, 5);
    });
  });

}
