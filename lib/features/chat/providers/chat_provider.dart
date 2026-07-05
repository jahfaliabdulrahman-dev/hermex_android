import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/sse_client.dart';
import '../../../core/auth/auth_manager.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../models/chat_message.dart';
import '../../../models/model_info.dart';
import '../../../models/stream_event.dart';
import '../data/chat_repository.dart';

/// Complete UI state for the chat feature.
class ChatState {
  final List<ChatMessage> messages;
  final String? selectedModelId;
  final String? sessionId;
  final bool isStreaming;
  final String? errorMessage;
  final List<ModelInfo> availableModels;
  final bool isLoadingModels;
  final bool isLoadingHistory;
  final bool isInitialized;

  const ChatState({
    this.messages = const [],
    this.selectedModelId,
    this.sessionId,
    this.isStreaming = false,
    this.errorMessage,
    this.availableModels = const [],
    this.isLoadingModels = false,
    this.isLoadingHistory = false,
    this.isInitialized = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    String? selectedModelId,
    bool clearSelectedModel = false,
    String? sessionId,
    bool clearSession = false,
    bool? isStreaming,
    String? errorMessage,
    bool clearError = false,
    List<ModelInfo>? availableModels,
    bool? isLoadingModels,
    bool? isLoadingHistory,
    bool? isInitialized,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        selectedModelId: clearSelectedModel
            ? null
            : (selectedModelId ?? this.selectedModelId),
        sessionId: clearSession ? null : (sessionId ?? this.sessionId),
        isStreaming: isStreaming ?? this.isStreaming,
        errorMessage:
            clearError ? null : (errorMessage ?? this.errorMessage),
        availableModels: availableModels ?? this.availableModels,
        isLoadingModels: isLoadingModels ?? this.isLoadingModels,
        isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
        isInitialized: isInitialized ?? this.isInitialized,
      );
}

/// Riverpod notifier for all chat state management.
///
/// Responsibilities:
/// - Initialize repository from active server config
/// - Load available models
/// - Send messages (streaming + non-streaming fallback)
/// - Manage message list (append user messages, accumulate agent deltas)
/// - Handle tool progress events
/// - Stop active streams
/// - Load session history
///
/// NOT autoDispose — shared long-lived controller (DEC-034 rule 2).
class ChatNotifier extends Notifier<ChatState> {
  ChatRepository? _repository;
  StreamSubscription<StreamEvent>? _streamSubscription;

  @override
  ChatState build() {
    // Register cleanup via Riverpod's lifecycle.
    ref.onDispose(() {
      _streamSubscription?.cancel();
      _repository?.dispose();
    });

    // Start uninitialized. The UI calls initialize() on first build.
    return const ChatState();
  }

  /// Initialize the repository from the active server configuration.
  ///
  /// Must be called before any chat operations. Safe to call multiple times —
  /// subsequent calls are no-ops if already initialized.
  Future<void> initialize() async {
    if (state.isInitialized && _repository != null) return;

    debugPrint('=== HERMEX DEBUG: ChatNotifier.initialize ===');

    try {
      final authManager = AuthManager(secureStorage: SecureStorage());
      final config = await authManager.getActiveServerConfig();
      final apiKey = await authManager.getApiKey();

      if (config == null || apiKey == null) {
        state = state.copyWith(
          isInitialized: true,
          errorMessage: 'No active server. Please connect first.',
          clearError: false,
        );
        return;
      }

      _repository = ChatRepository(
        apiClient: ApiClient(baseUrl: config.url, apiKey: apiKey),
        sseClient: SseClient(baseUrl: config.url),
        apiKey: apiKey,
      );

      state = state.copyWith(isInitialized: true, clearError: true);

      // Load models after initialization.
      await loadModels();
    } catch (e) {
      debugPrint(
          '=== HERMEX DEBUG: ChatNotifier.initialize error — $e ===');
      state = state.copyWith(
        isInitialized: true,
        errorMessage: 'Failed to initialize chat: $e',
      );
    }
  }

  // ─── Models ────────────────────────────────────────────────────────────

  /// Load available models from the server.
  Future<void> loadModels() async {
    if (_repository == null) return;

    debugPrint('=== HERMEX DEBUG: ChatNotifier.loadModels ===');

    state = state.copyWith(isLoadingModels: true, clearError: true);

    try {
      final models = await _repository!.getModels();
      state = state.copyWith(
        availableModels: models,
        isLoadingModels: false,
        // Auto-select first model if none selected.
        selectedModelId: state.selectedModelId ?? _firstModelId(models),
      );
    } catch (e) {
      debugPrint(
          '=== HERMEX DEBUG: ChatNotifier.loadModels error — $e ===');
      state = state.copyWith(
        isLoadingModels: false,
        errorMessage: 'Failed to load models. Using last known model.',
      );
    }
  }

  /// Select a model for chat.
  void selectModel(String modelId) {
    debugPrint(
        '=== HERMEX DEBUG: ChatNotifier.selectModel — $modelId ===');
    state = state.copyWith(selectedModelId: modelId);
  }

  // ─── Send Message ──────────────────────────────────────────────────────

  /// Send a user message and stream the agent response.
  ///
  /// Flow:
  /// 1. Validate message (non-empty) and model selection
  /// 2. Append user message to list
  /// 3. Append a placeholder streaming agent message
  /// 4. Connect to SSE stream
  /// 5. On TextDelta: append text to the agent message
  /// 6. On ToolProgress: insert a tool bubble
  /// 7. On StreamDone: finalize the agent message
  /// 8. On StreamError: show error
  ///
  /// Returns true if the message was sent successfully.
  Future<bool> sendMessage(String text) async {
    if (_repository == null) {
      state = state.copyWith(
        errorMessage: 'Chat not initialized. Please reconnect.',
      );
      return false;
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      debugPrint(
          '=== HERMEX DEBUG: ChatNotifier.sendMessage — blocked: empty message ===');
      return false;
    }

    if (state.selectedModelId == null) {
      state = state.copyWith(
        errorMessage: 'No model selected. Please select a model.',
      );
      return false;
    }

    // Prevent duplicate sends during active stream.
    if (state.isStreaming) {
      debugPrint(
          '=== HERMEX DEBUG: ChatNotifier.sendMessage — blocked: already streaming ===');
      return false;
    }

    debugPrint(
        '=== HERMEX DEBUG: ChatNotifier.sendMessage — model=${state.selectedModelId} ===');

    // 1. Append user message.
    final userMessage = ChatMessage(
      role: 'user',
      content: trimmed,
      timestamp: DateTime.now(),
    );

    // 2. Append placeholder streaming agent message.
    final agentMessage = ChatMessage(
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage, agentMessage],
      isStreaming: true,
      clearError: true,
    );

    // Build message history for context (last 20 messages, excluding streaming).
    final history = _buildHistory();

    // 3. Connect to SSE stream.
    try {
      final stream = _repository!.streamChatCompletion(
        message: trimmed,
        model: state.selectedModelId!,
        history: history,
      );

      _streamSubscription = stream.listen(
        (event) => _handleStreamEvent(event, state.messages.length - 1),
        onError: (error) => _handleStreamError(error),
        onDone: () => _handleStreamDone(),
        cancelOnError: false,
      );

      return true;
    } catch (e) {
      debugPrint(
          '=== HERMEX DEBUG: ChatNotifier.sendMessage stream error — $e ===');

      // Fallback: non-streaming request.
      try {
        final response = await _repository!.sendChatCompletion(
          message: trimmed,
          model: state.selectedModelId!,
        );

        // Replace the placeholder with the actual response.
        final messages = List<ChatMessage>.from(state.messages);
        messages.removeLast(); // Remove placeholder
        messages.add(ChatMessage(
          role: 'assistant',
          content: response,
          timestamp: DateTime.now(),
        ));

        state = state.copyWith(messages: messages, isStreaming: false);
        return true;
      } catch (fallbackError) {
        _handleStreamError(fallbackError);
        return false;
      }
    }
  }

  /// Stop the active stream generation.
  void stopGeneration() {
    debugPrint('=== HERMEX DEBUG: ChatNotifier.stopGeneration ===');

    _streamSubscription?.cancel();
    _streamSubscription = null;
    _repository?.cancelStream();

    // Finalize any streaming message.
    final messages = List<ChatMessage>.from(state.messages);
    if (messages.isNotEmpty && messages.last.isStreaming) {
      messages[messages.length - 1] = messages.last.copyWith(
        isStreaming: false,
      );
    }

    state = state.copyWith(messages: messages, isStreaming: false);
  }

  // ─── Session History ───────────────────────────────────────────────────

  /// Load chat history for a session.
  Future<void> loadHistory(String sessionId) async {
    if (_repository == null) return;

    debugPrint(
        '=== HERMEX DEBUG: ChatNotifier.loadHistory — session=$sessionId ===');

    state = state.copyWith(
      isLoadingHistory: true,
      sessionId: sessionId,
      clearError: true,
    );

    try {
      final messages = await _repository!.getSessionMessages(sessionId);
      state = state.copyWith(
        messages: messages,
        isLoadingHistory: false,
      );
    } catch (e) {
      debugPrint(
          '=== HERMEX DEBUG: ChatNotifier.loadHistory error — $e ===');
      state = state.copyWith(
        isLoadingHistory: false,
        errorMessage: 'Failed to load session history.',
      );
    }
  }

  /// Clear the current session association.
  void clearSession() {
    state = state.copyWith(clearSession: true);
  }

  // ─── Error Handling ────────────────────────────────────────────────────

  /// Clear the current error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ─── Internal: Stream Event Handling ───────────────────────────────────

  /// Handle a single SSE [event], updating the message at [agentIndex].
  void _handleStreamEvent(StreamEvent event, int agentIndex) {
    switch (event) {
      case TextDelta(:final text):
        _appendToAgentMessage(text, agentIndex);

      case ToolProgress(:final toolName, :final status):
        _insertToolMessage(toolName, status);

      case StreamDone():
        // Handled by onDone callback.
        break;

      case StreamError(:final message):
        _handleStreamError(message);
    }
  }

  /// Append text to the agent message at [agentIndex].
  void _appendToAgentMessage(String text, int agentIndex) {
    final messages = List<ChatMessage>.from(state.messages);
    if (agentIndex < 0 || agentIndex >= messages.length) return;

    final msg = messages[agentIndex];
    if (msg.role != 'assistant') return;

    messages[agentIndex] = msg.copyWith(
      content: msg.content + text,
    );

    state = state.copyWith(messages: messages);
  }

  /// Insert a tool progress bubble into the message list.
  void _insertToolMessage(String toolName, String status) {
    final messages = List<ChatMessage>.from(state.messages);

    // Insert before the last message (the streaming agent message).
    final insertIndex = messages.length - 1;
    final toolMessage = ChatMessage(
      role: 'tool',
      content: status == 'started' ? 'Using tool: $toolName' : '$toolName: $status',
      toolName: toolName,
      timestamp: DateTime.now(),
    );

    messages.insert(insertIndex, toolMessage);
    state = state.copyWith(messages: messages);
  }

  /// Handle a stream error.
  void _handleStreamError(dynamic error) {
    debugPrint(
        '=== HERMEX DEBUG: ChatNotifier stream error — $error ===');

    _streamSubscription?.cancel();
    _streamSubscription = null;

    // Finalize streaming message and append error.
    final messages = List<ChatMessage>.from(state.messages);
    if (messages.isNotEmpty && messages.last.isStreaming) {
      messages[messages.length - 1] = messages.last.copyWith(
        isStreaming: false,
      );
    }

    final errorText = error is String ? error : error.toString();
    messages.add(ChatMessage(
      role: 'system',
      content: 'Error: $errorText',
      timestamp: DateTime.now(),
    ));

    state = state.copyWith(
      messages: messages,
      isStreaming: false,
      errorMessage: errorText,
    );
  }

  /// Handle stream completion.
  void _handleStreamDone() {
    debugPrint('=== HERMEX DEBUG: ChatNotifier stream done ===');

    _streamSubscription?.cancel();
    _streamSubscription = null;

    final messages = List<ChatMessage>.from(state.messages);
    if (messages.isNotEmpty && messages.last.isStreaming) {
      messages[messages.length - 1] = messages.last.copyWith(
        isStreaming: false,
      );
    }

    state = state.copyWith(messages: messages, isStreaming: false);
  }

  // ─── Internal: Helpers ─────────────────────────────────────────────────

  /// Build message history as a list of JSON maps for the API.
  /// Excludes the currently-streaming message and limits to last 20.
  List<Map<String, dynamic>> _buildHistory() {
    return state.messages
        .where((m) => !m.isStreaming && m.role != 'tool' && m.role != 'system')
        .map((m) => {
              'role': m.role,
              'content': m.content,
            })
        .toList();
  }

  /// Get the first model ID from a list, or null if empty.
  String? _firstModelId(List<ModelInfo> models) {
    return models.isNotEmpty ? models.first.id : null;
  }
}

// ─── Riverpod Provider ───────────────────────────────────────────────────

/// Provider for the chat state notifier.
/// NOT autoDispose — shared, long-lived controller (DEC-034 rule 2).
final chatProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
