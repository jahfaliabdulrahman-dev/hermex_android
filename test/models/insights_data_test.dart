import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/models/insights_data.dart';

void main() {
  group('InsightsData — fromJson', () {
    test('parses complete insights data', () {
      final json = {
        'total_sessions': 42,
        'total_messages': 1234,
        'total_tokens': 567890,
        'active_time_minutes': 360,
        'last_synced': '2026-07-05T10:00:00Z',
        'cron_jobs_run': 15,
        'skills_count': 8,
      };

      final data = InsightsData.fromJson(json);

      expect(data.totalSessions, 42);
      expect(data.totalMessages, 1234);
      expect(data.totalTokens, 567890);
      expect(data.activeTimeMinutes, 360);
      expect(data.cronJobsRun, 15);
      expect(data.skillsCount, 8);
    });

    test('parses camelCase keys', () {
      final json = {
        'totalSessions': 10,
        'totalMessages': 100,
        'totalTokens': 1000,
        'activeTimeMinutes': 60,
        'cronJobsRun': 5,
        'skillsCount': 3,
      };

      final data = InsightsData.fromJson(json);

      expect(data.totalSessions, 10);
      expect(data.totalMessages, 100);
    });

    test('defaults missing values to 0', () {
      final data = InsightsData.fromJson({});

      expect(data.totalSessions, 0);
      expect(data.totalMessages, 0);
      expect(data.totalTokens, 0);
      expect(data.activeTimeMinutes, 0);
    });

    test('handles string number values', () {
      final json = {
        'total_sessions': '42',
        'total_tokens': '567890',
      };

      final data = InsightsData.fromJson(json);

      expect(data.totalSessions, 42);
      expect(data.totalTokens, 567890);
    });

    test('handles null values', () {
      final json = {
        'total_sessions': null,
        'total_tokens': null,
      };

      final data = InsightsData.fromJson(json);

      expect(data.totalSessions, 0);
      expect(data.totalTokens, 0);
    });
  });

  group('InsightsData — parse', () {
    test('parses direct JSON', () {
      final body = {
        'total_sessions': 5,
        'total_messages': 50,
      };

      final data = InsightsData.parse(body);

      expect(data.totalSessions, 5);
      expect(data.totalMessages, 50);
    });

    test('parses wrapped in "insights" key', () {
      final body = {
        'insights': {
          'total_sessions': 5,
          'total_messages': 50,
        },
      };

      final data = InsightsData.parse(body);

      expect(data.totalSessions, 5);
    });

    test('parses wrapped in "data" key', () {
      final body = {
        'data': {
          'total_sessions': 5,
        },
      };

      final data = InsightsData.parse(body);

      expect(data.totalSessions, 5);
    });

    test('returns default for null', () {
      final data = InsightsData.parse(null);

      expect(data.totalSessions, 0);
    });
  });

  group('InsightsData — formattedActiveTime', () {
    test('formats hours and minutes', () {
      final data = InsightsData(activeTimeMinutes: 125);
      expect(data.formattedActiveTime, '2h 5m');
    });

    test('formats hours only', () {
      final data = InsightsData(activeTimeMinutes: 120);
      expect(data.formattedActiveTime, '2h');
    });

    test('formats minutes only', () {
      final data = InsightsData(activeTimeMinutes: 45);
      expect(data.formattedActiveTime, '45m');
    });

    test('formats zero as 0m', () {
      final data = InsightsData(activeTimeMinutes: 0);
      expect(data.formattedActiveTime, '0m');
    });
  });

  group('InsightsData — formattedTokens', () {
    test('formats millions', () {
      final data = InsightsData(totalTokens: 2500000);
      expect(data.formattedTokens, '2.5M');
    });

    test('formats thousands', () {
      final data = InsightsData(totalTokens: 5678);
      expect(data.formattedTokens, '5.7k');
    });

    test('formats small numbers', () {
      final data = InsightsData(totalTokens: 42);
      expect(data.formattedTokens, '42');
    });
  });

  group('InsightsData — equality', () {
    test('two identical data are equal', () {
      final a = InsightsData(totalSessions: 1, totalMessages: 2);
      final b = InsightsData(totalSessions: 1, totalMessages: 2);
      expect(a, equals(b));
    });

    test('different data are not equal', () {
      final a = InsightsData(totalSessions: 1);
      final b = InsightsData(totalSessions: 2);
      expect(a, isNot(equals(b)));
    });
  });
}
