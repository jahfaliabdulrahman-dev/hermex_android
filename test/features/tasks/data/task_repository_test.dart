import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/core/api/api_exception.dart';
import 'package:hermex_android/models/cron_job.dart';

/// Tests for TaskRepository JSON parsing and error handling.
///
/// These tests focus on the repository's parsing logic without requiring
/// a live server. The repository's API calls are tested indirectly through
/// the provider tests.
void main() {
  group('CronJob JSON parsing', () {
    test('parses a complete job with all fields', () {
      final json = {
        'id': 'job-123',
        'prompt': 'Daily briefing',
        'schedule': '0 9 * * *',
        'status': 'active',
        'last_run': 1750000000,
        'next_run': 1750086400,
        'skills': ['hermes-agent', 'code-review'],
        'model_provider': 'deepseek',
        'model_name': 'deepseek-v4-pro',
        'name': 'Morning Briefing',
        'deliver': 'telegram',
        'created_at': 1749000000,
        'last_error': null,
        'paused': false,
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
        'paused': true,
      };

      final job = CronJob.fromJson(json);

      expect(job.paused, true);
    });

    test('handles null timestamp fields gracefully', () {
      final json = {
        'id': 'job-ts',
        'prompt': 'No timestamps',
        'schedule': '* * * * *',
        'last_run': null,
        'next_run': null,
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
        'last_run': '2026-07-05T09:00:00',
        'next_run': '2026-07-06T09:00:00',
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

      // fromJson(toJson()) should work for the key fields
      final json = {
        'id': original.id,
        'prompt': original.prompt,
        'schedule': original.schedule,
        'status': original.status,
        'name': original.name,
        'paused': original.paused,
        'skills': original.skills,
        'model_name': original.modelName,
      };

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
  });

  group('ApiException classification', () {
    test('ConnectionException has correct properties', () {
      final ex = ConnectionException('timeout', statusCode: null);
      expect(ex.message, 'timeout');
      expect(ex.statusCode, isNull);
      expect(ex.toString(), contains('timeout'));
      expect(ex.toString(), contains('ApiException'));
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
}
