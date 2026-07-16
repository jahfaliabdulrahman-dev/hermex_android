import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/models/chat_message.dart';

void main() {
  group('ChatMessage — fromJson', () {
    test('parses a user message', () {
      final json = {
        'role': 'user',
        'content': 'Hello, what models do you support?',
        'timestamp': 1700000000,
      };

      final msg = ChatMessage.fromJson(json);

      expect(msg.role, 'user');
      expect(msg.content, 'Hello, what models do you support?');
      expect(msg.timestamp, DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000));
    });

    test('parses an assistant message', () {
      final json = {
        'role': 'assistant',
        'content': 'I support deepseek-v4-pro, qwen3.7-max, and glm-5.2.',
        'timestamp': '2026-07-05T10:00:00Z',
      };

      final msg = ChatMessage.fromJson(json);

      expect(msg.role, 'assistant');
      expect(msg.content, 'I support deepseek-v4-pro, qwen3.7-max, and glm-5.2.');
    });

    test('parses a tool message', () {
      final json = {
        'role': 'tool',
        'content': 'Search results...',
        'tool_call_id': 'tc-123',
        'tool_name': 'web_search',
      };

      final msg = ChatMessage.fromJson(json);

      expect(msg.role, 'tool');
      expect(msg.toolCallId, 'tc-123');
      expect(msg.toolName, 'web_search');
    });

    test('parses a system message', () {
      final json = {
        'role': 'system',
        'content': 'You are a helpful assistant.',
      };

      final msg = ChatMessage.fromJson(json);

      expect(msg.role, 'system');
      expect(msg.content, 'You are a helpful assistant.');
    });

    test('parses tool_calls array', () {
      final json = {
        'role': 'assistant',
        'content': '',
        'tool_calls': [
          {
            'id': 'tc-1',
            'type': 'function',
            'function': {
              'name': 'web_search',
              'arguments': '{"query":"flutter"}',
            },
          },
        ],
      };

      final msg = ChatMessage.fromJson(json);

      expect(msg.toolCalls.length, 1);
      expect(msg.toolCalls.first.id, 'tc-1');
      expect(msg.toolCalls.first.function.name, 'web_search');
      expect(msg.toolCalls.first.function.arguments, '{"query":"flutter"}');
    });

    test('defaults missing fields', () {
      final json = {
        'role': 'user',
        'content': 'Hello',
      };

      final msg = ChatMessage.fromJson(json);

      expect(msg.toolCallId, isNull);
      expect(msg.toolName, isNull);
      expect(msg.timestamp, isNull);
      expect(msg.toolCalls, isEmpty);
      expect(msg.isStreaming, false);
      expect(msg.id, isNull);
    });

    test('handles null timestamp', () {
      final json = {
        'role': 'user',
        'content': 'Hello',
        'timestamp': null,
      };

      final msg = ChatMessage.fromJson(json);

      expect(msg.timestamp, isNull);
    });

    // ─── BUG-RC6-SESSION-RESTORE regression tests ───
    // The live Hermes server sends message `id` as an int and `timestamp`
    // as a float (epoch seconds with fraction). Both previously threw or
    // silently dropped data, breaking history restore for EVERY session.
    test('parses real server payload shape: int id + float timestamp + null fields', () {
      final json = {
        'id': 4102,
        'session_id': '20260712_045131_469146',
        'role': 'user',
        'content': 'مرحبا',
        'timestamp': 1752629471.831553,
        'tool_call_id': null,
        'tool_calls': null,
        'tool_name': null,
        'token_count': null,
      };

      final msg = ChatMessage.fromJson(json);

      expect(msg.id, '4102');
      expect(msg.role, 'user');
      expect(msg.content, 'مرحبا');
      expect(
        msg.timestamp,
        DateTime.fromMillisecondsSinceEpoch(
            (1752629471.831553 * 1000).round()),
      );
      expect(msg.toolCallId, isNull);
      expect(msg.toolCalls, isEmpty);
    });

    test('parses int tool_call_id tolerantly', () {
      final json = {
        'role': 'tool',
        'content': 'result',
        'tool_call_id': 987,
      };

      final msg = ChatMessage.fromJson(json);

      expect(msg.toolCallId, '987');
    });

    test('parses int timestamp (epoch seconds) unchanged', () {
      final json = {
        'role': 'user',
        'content': 'Hello',
        'timestamp': 1700000000,
      };

      final msg = ChatMessage.fromJson(json);

      expect(msg.timestamp,
          DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000));
    });
  });

  group('ChatMessage — equality', () {
    test('two messages with same fields are equal', () {
      final a = ChatMessage(role: 'user', content: 'Hello');
      final b = ChatMessage(role: 'user', content: 'Hello');
      expect(a, equals(b));
    });

    test('two messages with different roles are not equal', () {
      final a = ChatMessage(role: 'user', content: 'Hello');
      final b = ChatMessage(role: 'assistant', content: 'Hello');
      expect(a, isNot(equals(b)));
    });
  });

  group('ToolCall — fromJson', () {
    test('parses a complete tool call', () {
      final json = {
        'id': 'tc-1',
        'type': 'function',
        'function': {
          'name': 'web_search',
          'arguments': '{"query":"test"}',
        },
      };

      final tc = ToolCall.fromJson(json);

      expect(tc.id, 'tc-1');
      expect(tc.type, 'function');
      expect(tc.function.name, 'web_search');
      expect(tc.function.arguments, '{"query":"test"}');
    });

    test('defaults arguments to "{}" when missing', () {
      final json = {
        'function': {'name': 'test'},
      };

      final tc = ToolCall.fromJson(json);

      expect(tc.function.arguments, '{}');
    });
  });

  group('ToolCallFunction — fromJson', () {
    test('parses function name and arguments', () {
      final json = {
        'name': 'read_file',
        'arguments': '{"path":"/tmp/test"}',
      };

      final fn = ToolCallFunction.fromJson(json);

      expect(fn.name, 'read_file');
      expect(fn.arguments, '{"path":"/tmp/test"}');
    });
  });
}
