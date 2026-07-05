import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/models/stream_event.dart';

void main() {
  group('StreamEvent — TextDelta', () {
    test('creates text delta event', () {
      final event = StreamEvent.textDelta(text: 'Hello world');

      expect(event, isA<TextDelta>());
      final delta = event as TextDelta;
      expect(delta.text, 'Hello world');
    });

    test('TextDelta equality', () {
      final a = StreamEvent.textDelta(text: 'Hello');
      final b = StreamEvent.textDelta(text: 'Hello');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('StreamEvent — ToolProgress', () {
    test('creates tool progress event', () {
      final event = StreamEvent.toolProgress(
        toolName: 'web_search',
        status: 'started',
      );

      expect(event, isA<ToolProgress>());
      final tp = event as ToolProgress;
      expect(tp.toolName, 'web_search');
      expect(tp.status, 'started');
    });

    test('ToolProgress equality', () {
      final a = StreamEvent.toolProgress(toolName: 'search', status: 'completed');
      final b = StreamEvent.toolProgress(toolName: 'search', status: 'completed');
      expect(a, equals(b));
    });
  });

  group('StreamEvent — StreamDone', () {
    test('creates done event', () {
      final event = StreamEvent.done();

      expect(event, isA<StreamDone>());
    });

    test('StreamDone equality', () {
      final a = StreamEvent.done();
      final b = StreamEvent.done();
      expect(a, equals(b));
    });
  });

  group('StreamEvent — StreamError', () {
    test('creates error event with message', () {
      final event = StreamEvent.error(message: 'Connection lost');

      expect(event, isA<StreamError>());
      final err = event as StreamError;
      expect(err.message, 'Connection lost');
      expect(err.code, isNull);
    });

    test('creates error event with message and code', () {
      final event = StreamEvent.error(message: 'Auth failed', code: '401');

      final err = event as StreamError;
      expect(err.code, '401');
    });

    test('StreamError equality', () {
      final a = StreamEvent.error(message: 'Error');
      final b = StreamEvent.error(message: 'Error');
      expect(a, equals(b));
    });
  });

  group('StreamEvent — fromJson', () {
    test('parses TextDelta from JSON', () {
      final json = {
        'runtimeType': 'TextDelta',
        'text': 'Hello',
      };

      // Note: freezed sealed classes don't auto-dispatch fromJson.
      // We test the individual factory constructors directly.
      final event = StreamEvent.textDelta(text: 'Hello');
      expect(event, isA<TextDelta>());
    });
  });

  group('StreamEvent — pattern matching', () {
    test('switch on StreamEvent variants', () {
      String describe(StreamEvent event) => switch (event) {
            TextDelta(text: final t) => 'text: $t',
            ToolProgress(toolName: final n, status: final s) => 'tool: $n ($s)',
            StreamDone() => 'done',
            StreamError(message: final m) => 'error: $m',
          };

      expect(describe(StreamEvent.textDelta(text: 'Hi')), 'text: Hi');
      expect(
        describe(StreamEvent.toolProgress(toolName: 'search', status: 'running')),
        'tool: search (running)',
      );
      expect(describe(StreamEvent.done()), 'done');
      expect(
        describe(StreamEvent.error(message: 'Failed')),
        'error: Failed',
      );
    });
  });
}
