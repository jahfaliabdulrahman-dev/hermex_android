import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/api/sse_client.dart';
import '../../../models/chat_message.dart';
import '../../../models/model_info.dart';
import '../../../models/stream_event.dart';

/// Repository for chat operations — REST calls + SSE streaming delegation.
///
/// Uses [ApiClient] for standard JSON REST endpoints (models, session messages).
/// Uses [SseClient] for SSE streaming (chat completions with stream=true).
///
/// Transaction boundaries: this repository does NOT own writeTxn boundaries.
/// It delegates streaming to [SseClient] which manages its own HTTP lifecycle.
class ChatRepository {
  final ApiClient _apiClient;
  final SseClient _sseClient;
  final String _apiKey;

  ChatRepository({
    required ApiClient apiClient,
    required SseClient sseClient,
    required String apiKey,
  })  : _apiClient = apiClient,
        _sseClient = sseClient,
        _apiKey = apiKey;

  // ─── REST: Models ──────────────────────────────────────────────────────

  /// Fetch available models from GET /v1/models.
  ///
  /// Returns a list of [ModelInfo] parsed from the server response.
  /// Throws [ApiException] on non-200 responses.
  Future<List<ModelInfo>> getModels() async {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: ChatRepository.getModels ===');
    }

    try {
      final data = await _apiClient.getDynamic(ApiEndpoints.models);
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: ChatRepository.getModels — raw response type=${data.runtimeType} ===');
      }

      final List<dynamic> modelList;
      if (data is List) {
        modelList = data;
      } else if (data is Map<String, dynamic>) {
        modelList = (data['data'] as List<dynamic>?) ?? [];
      } else {
        modelList = [];
      }

      return modelList
          .map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('=== HERMEX DEBUG: ChatRepository.getModels error — $e ===');
      }
      throw ClientException('Failed to load models: $e');
    }
  }

  // ─── REST: Session Messages ────────────────────────────────────────────

  /// Load message history for a session from GET /api/sessions/{id}/messages.
  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: ChatRepository.getSessionMessages — session=$sessionId ===');
    }

    try {
      final json = await _apiClient.get(
        ApiEndpoints.sessionMessages(sessionId),
      );
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: ChatRepository.getSessionMessages — '
          'response keys=${json.keys.toList()} ===');
      }
      final messages = json['data'] as List<dynamic>?;
      if (messages == null) {
        if (kDebugMode) {
          debugPrint(
            '=== HERMEX DEBUG: ChatRepository.getSessionMessages — '
            'no "data" key in response. Present keys: ${json.keys.toList()} ===');
        }
        return [];
      }

      return messages
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: ChatRepository.getSessionMessages error — $e ===');
      }
      throw ClientException('Failed to load messages: $e');
    }
  }

  // ─── SSE: Chat Completions (streaming) ─────────────────────────────────

  /// Stream chat completions via SSE from POST /v1/chat/completions.
  ///
  /// Sends a chat completion request with `stream: true` and returns
  /// a [Stream] of [StreamEvent] objects parsed from the SSE response.
  ///
  /// [message] — the user's message text
  /// [model] — the model ID to use
  /// [history] — previous messages for context (optional)
  ///
  /// The stream emits: TextDelta, ToolProgress, StreamDone, StreamError.
  Stream<StreamEvent> streamChatCompletion({
    required String message,
    required String model,
    List<Map<String, dynamic>>? history,
  }) {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: ChatRepository.streamChatCompletion — model=$model ===');
    }

    final messages = <Map<String, dynamic>>[];

    // Include history if provided.
    if (history != null && history.isNotEmpty) {
      messages.addAll(history);
    }

    // Add the current user message.
    messages.add({
      'role': 'user',
      'content': message,
    });

    final body = {
      'model': model,
      'messages': messages,
      'stream': true,
    };

    return _sseClient.connect(
      ApiEndpoints.chatCompletions,
      apiKey: _apiKey,
      body: body,
    );
  }

  /// Stream chat via session-based endpoint POST /api/sessions/{id}/chat/stream.
  ///
  /// Used when chatting within an existing Hermes session context.
  Stream<StreamEvent> streamSessionChat({
    required String sessionId,
    required String message,
    required String model,
  }) {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: ChatRepository.streamSessionChat — session=$sessionId, model=$model ===');
    }

    final body = {
      'message': message,
      'model': model,
    };

    return _sseClient.connect(
      ApiEndpoints.sessionChatStream(sessionId),
      apiKey: _apiKey,
      body: body,
    );
  }

  // ─── Non-streaming Fallback ────────────────────────────────────────────

  /// Send a non-streaming chat completion (fallback when SSE is unavailable).
  ///
  /// Returns the full response text. Used as fallback when SSE connection fails.
  Future<String> sendChatCompletion({
    required String message,
    required String model,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: ChatRepository.sendChatCompletion (non-streaming) — model=$model ===');
    }

    try {
      final body = {
        'model': model,
        'messages': [
          {'role': 'user', 'content': message},
        ],
        'stream': false,
      };

      final json = await _apiClient.post(
        ApiEndpoints.chatCompletions,
        data: body,
      );

      final choices = json['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>?;
        return message?['content'] as String? ?? '';
      }
      return '';
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: ChatRepository.sendChatCompletion error — $e ===');
      }
      throw ClientException('Chat request failed: $e');
    }
  }

  // ─── Stream Lifecycle ──────────────────────────────────────────────────

  /// Cancel the active SSE stream.
  void cancelStream() {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: ChatRepository.cancelStream ===');
    }
    _sseClient.cancel();
  }

  /// Dispose the repository and underlying clients.
  void dispose() {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: ChatRepository.dispose ===');
    }
    _sseClient.dispose();
  }
}
