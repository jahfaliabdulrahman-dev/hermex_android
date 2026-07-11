import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/chat/providers/chat_provider.dart';
import 'package:hermex_android/models/chat_message.dart';

void main() {
  group('ChatState', () {
    test('default state has null session fields', () {
      const state = ChatState();
      expect(state.sessionId, isNull);
      expect(state.sessionTitle, isNull);
      expect(state.sessionModelName, isNull);
      expect(state.messages, isEmpty);
      expect(state.isInitialized, isFalse);
    });

    test('copyWith sets sessionTitle', () {
      const state = ChatState();
      final updated = state.copyWith(sessionTitle: 'My Session');
      expect(updated.sessionTitle, 'My Session');
      expect(updated.sessionId, isNull); // unchanged
    });

    test('copyWith sets sessionModelName', () {
      const state = ChatState();
      final updated = state.copyWith(sessionModelName: 'hermes-pro');
      expect(updated.sessionModelName, 'hermes-pro');
    });

    test('copyWith sets both sessionId and title/model', () {
      const state = ChatState();
      final updated = state.copyWith(
        sessionId: 'abc-123',
        sessionTitle: 'Test Chat',
        sessionModelName: 'gpt-4',
      );
      expect(updated.sessionId, 'abc-123');
      expect(updated.sessionTitle, 'Test Chat');
      expect(updated.sessionModelName, 'gpt-4');
    });

    test('copyWith clearSessionTitle clears the title', () {
      const state = ChatState(sessionTitle: 'Old Title');
      final updated = state.copyWith(clearSessionTitle: true);
      expect(updated.sessionTitle, isNull);
    });

    test('copyWith clearSessionModelName clears the model name', () {
      const state = ChatState(sessionModelName: 'old-model');
      final updated = state.copyWith(clearSessionModelName: true);
      expect(updated.sessionModelName, isNull);
    });

    test('copyWith clearSession clears sessionId, title, and modelName', () {
      const state = ChatState(
        sessionId: 's1',
        sessionTitle: 'T1',
        sessionModelName: 'M1',
      );
      final updated = state.copyWith(
        clearSession: true,
        clearSessionTitle: true,
        clearSessionModelName: true,
      );
      expect(updated.sessionId, isNull);
      expect(updated.sessionTitle, isNull);
      expect(updated.sessionModelName, isNull);
    });

    test('copyWith preserves existing messages', () {
      final messages = [
        ChatMessage(role: 'user', content: 'Hello'),
        ChatMessage(role: 'assistant', content: 'Hi there'),
      ];
      final state = ChatState(messages: messages);
      final updated = state.copyWith(sessionTitle: 'Chat');
      expect(updated.messages, hasLength(2));
      expect(updated.messages.first.content, 'Hello');
    });

    test('copyWith with session fields does not mutate original state', () {
      const original = ChatState();
      // ignore: unused_local_variable
      final updated = original.copyWith(sessionTitle: 'New');
      expect(original.sessionTitle, isNull);
    });

    // ─── Session-aware state transitions ───
    test('state with sessionId set is not "new chat" state', () {
      final state = ChatState(
        sessionId: 'sess-1',
        sessionTitle: 'My Chat',
      );
      expect(state.sessionId, isNotNull);
      expect(state.sessionTitle, isNotNull);
    });

    test('isLoadingHistory is false by default', () {
      const state = ChatState();
      expect(state.isLoadingHistory, isFalse);
    });

    test('isLoadingHistory can be set via copyWith', () {
      const state = ChatState();
      final updated = state.copyWith(isLoadingHistory: true);
      expect(updated.isLoadingHistory, isTrue);
    });

    test('errorMessage can be cleared while setting session', () {
      const state = ChatState(errorMessage: 'Some error');
      final updated = state.copyWith(
        sessionId: 's1',
        clearError: true,
      );
      expect(updated.sessionId, 's1');
      expect(updated.errorMessage, isNull);
    });

    test('isStreaming is false by default', () {
      const state = ChatState();
      expect(state.isStreaming, isFalse);
    });

    test('availableModels defaults to empty list', () {
      const state = ChatState();
      expect(state.availableModels, isEmpty);
    });

    test('full state copyWith supports all session fields at once', () {
      const state = ChatState();
      final updated = state.copyWith(
        sessionId: 'full-session',
        sessionTitle: 'Full Chat',
        sessionModelName: 'full-model',
        isInitialized: true,
        isLoadingHistory: false,
        isStreaming: false,
      );
      expect(updated.sessionId, 'full-session');
      expect(updated.sessionTitle, 'Full Chat');
      expect(updated.sessionModelName, 'full-model');
      expect(updated.isInitialized, isTrue);
    });
  });
}
