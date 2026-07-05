import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hermex_android/features/chat/providers/chat_provider.dart';
import 'package:hermex_android/models/chat_message.dart';
import 'package:hermex_android/models/model_info.dart';

void main() {
  // ─── ChatState — copyWith ────────────────────────────────────────────

  group('ChatState — copyWith', () {
    test('default state is uninitialized with empty messages', () {
      const state = ChatState();

      expect(state.messages, isEmpty);
      expect(state.selectedModelId, isNull);
      expect(state.isStreaming, false);
      expect(state.errorMessage, isNull);
      expect(state.availableModels, isEmpty);
      expect(state.isInitialized, false);
      expect(state.isLoadingModels, false);
      expect(state.isLoadingHistory, false);
    });

    test('updates messages', () {
      final state = const ChatState();
      final messages = [
        ChatMessage(role: 'user', content: 'Hello'),
      ];
      final updated = state.copyWith(messages: messages);

      expect(updated.messages, messages);
      expect(state.messages, isEmpty); // Original unchanged
    });

    test('updates selectedModelId', () {
      final state = const ChatState();
      final updated = state.copyWith(selectedModelId: 'deepseek-v4-pro');

      expect(updated.selectedModelId, 'deepseek-v4-pro');
    });

    test('clearSelectedModel sets to null', () {
      final state = const ChatState(selectedModelId: 'some-model');
      final updated = state.copyWith(clearSelectedModel: true);

      expect(updated.selectedModelId, isNull);
    });

    test('updates isStreaming flag', () {
      final state = const ChatState();
      final updated = state.copyWith(isStreaming: true);

      expect(updated.isStreaming, true);
    });

    test('clearError removes error message', () {
      final state = const ChatState(errorMessage: 'Something failed');
      final updated = state.copyWith(clearError: true);

      expect(updated.errorMessage, isNull);
    });

    test('updates availableModels', () {
      final state = const ChatState();
      final models = [
        ModelInfo(id: 'model-1'),
        ModelInfo(id: 'model-2'),
      ];
      final updated = state.copyWith(availableModels: models);

      expect(updated.availableModels, models);
    });

    test('updates isLoadingModels', () {
      final state = const ChatState();
      final updated = state.copyWith(isLoadingModels: true);

      expect(updated.isLoadingModels, true);
    });

    test('updates isLoadingHistory', () {
      final state = const ChatState();
      final updated = state.copyWith(isLoadingHistory: true);

      expect(updated.isLoadingHistory, true);
    });

    test('updates isInitialized', () {
      final state = const ChatState();
      final updated = state.copyWith(isInitialized: true);

      expect(updated.isInitialized, true);
    });

    test('preserves unchanged fields', () {
      final original = ChatState(
        messages: [ChatMessage(role: 'user', content: 'Hi')],
        selectedModelId: 'model-1',
        isStreaming: true,
        errorMessage: 'err',
        availableModels: [ModelInfo(id: 'model-1')],
        isLoadingModels: true,
        isLoadingHistory: false,
        isInitialized: true,
      );

      final updated = original.copyWith(selectedModelId: 'model-2');

      expect(updated.messages, original.messages);
      expect(updated.isStreaming, original.isStreaming);
      expect(updated.errorMessage, original.errorMessage);
      expect(updated.availableModels, original.availableModels);
    });
  });

  // ─── ChatNotifier — State Transitions ─────────────────────────────────

  group('ChatNotifier — state transitions', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('initial state is uninitialized', () {
      final state = container.read(chatProvider);

      expect(state.isInitialized, false);
      expect(state.messages, isEmpty);
    });

    test('selectModel updates selectedModelId', () {
      final notifier = container.read(chatProvider.notifier);

      notifier.selectModel('deepseek-v4-pro');

      final state = container.read(chatProvider);
      expect(state.selectedModelId, 'deepseek-v4-pro');
    });

    test('clearError removes error message', () {
      final notifier = container.read(chatProvider.notifier);

      notifier.clearError();

      final state = container.read(chatProvider);
      expect(state.errorMessage, isNull);
    });

    test('clearSession sets sessionId to null', () {
      final notifier = container.read(chatProvider.notifier);

      notifier.clearSession();

      final state = container.read(chatProvider);
      expect(state.sessionId, isNull);
    });

    test('stopGeneration sets isStreaming to false', () {
      final notifier = container.read(chatProvider.notifier);

      notifier.stopGeneration();

      final state = container.read(chatProvider);
      expect(state.isStreaming, false);
    });

    test('sendMessage returns false for empty text', () async {
      final notifier = container.read(chatProvider.notifier);

      final result = await notifier.sendMessage('   ');

      expect(result, false);
    });

    test('sendMessage returns false when uninitialized', () async {
      final notifier = container.read(chatProvider.notifier);

      final result = await notifier.sendMessage('Hello');

      expect(result, false);
      final state = container.read(chatProvider);
      expect(state.errorMessage, isNotNull);
    });
  });

  // ─── ChatState — Message Immutability ────────────────────────────────

  group('ChatState — message immutability', () {
    test('copyWith with messages creates new list', () {
      final original = ChatState(
        messages: [ChatMessage(role: 'user', content: 'Hello')],
      );

      final updated = original.copyWith(
        messages: [
          ...original.messages,
          ChatMessage(role: 'assistant', content: 'Hi'),
        ],
      );

      expect(original.messages.length, 1);
      expect(updated.messages.length, 2);
    });
  });
}
