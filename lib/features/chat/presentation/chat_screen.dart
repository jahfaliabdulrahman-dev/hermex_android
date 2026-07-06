import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../providers/chat_provider.dart';
import 'chat_input.dart';
import 'message_bubble.dart';

/// Main chat screen — F-002 flagship feature.
///
/// Layout:
/// - AppBar with session title and "New Chat" action
/// - Scrollable message list (ListView.builder, reverse) with auto-scroll
/// - "Scroll to bottom" FAB when user scrolls up
/// - ChatInput bar at the bottom
/// - Empty state when no messages
///
/// State handling: loading, success, error, empty.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showScrollFab = false;

  @override
  void initState() {
    super.initState();

    // Initialize chat after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).initialize();
    });

    // Listen for scroll position to show/hide FAB.
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showFab = _scrollController.hasClients &&
        _scrollController.position.pixels <
            _scrollController.position.maxScrollExtent - 200;

    if (showFab != _showScrollFab) {
      setState(() => _showScrollFab = showFab);
    }
  }

  /// Auto-scroll to the bottom after a new message is added.
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // reversed list — bottom is at 0
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSend() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    // If streaming, stop instead.
    final notifier = ref.read(chatProvider.notifier);
    if (ref.read(chatProvider).isStreaming) {
      notifier.stopGeneration();
      return;
    }

    _textController.clear();
    notifier.sendMessage(text);

    // Auto-scroll after sending.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _handleModelSelected(String modelId) {
    ref.read(chatProvider.notifier).selectModel(modelId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.sessionId != null ? 'Chat' : 'Hermes Chat',
        ),
        actions: [
          // New chat button.
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New Chat',
            onPressed: () {
              _textController.clear();
              ref.read(chatProvider.notifier).startNewChat();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ─── Message List ───
          Expanded(
            child: _buildMessageList(state),
          ),

          // ─── Error Banner ───
          if (state.errorMessage != null) _ErrorBanner(message: state.errorMessage!),

          // ─── Chat Input ───
          if (state.isInitialized)
            ChatInput(
              controller: _textController,
              isStreaming: state.isStreaming,
              selectedModelId: state.selectedModelId,
              availableModels: state.availableModels,
              onSend: _handleSend,
              onModelSelected: _handleModelSelected,
            )
          else
            _LoadingInput(),
        ],
      ),

      // ─── Scroll to Bottom FAB ───
      floatingActionButton: _showScrollFab
          ? FloatingActionButton.small(
              onPressed: _scrollToBottom,
              backgroundColor: HermesColors.surface,
              child: const Icon(Icons.arrow_downward, color: HermesColors.cyan),
            )
          : null,
    );
  }

  /// Build the message list with appropriate state handling.
  Widget _buildMessageList(ChatState state) {
    // Loading history.
    if (state.isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: HermesColors.cyan),
      );
    }

    // Loading models (initial state).
    if (!state.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: HermesColors.cyan),
      );
    }

    // Empty state.
    if (state.messages.isEmpty && state.errorMessage == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: HermesColors.textDisabled.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation with Hermes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: HermesColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            if (state.availableModels.isNotEmpty)
              Text(
                'Using ${state.selectedModelId ?? "default model"}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HermesColors.textDisabled,
                    ),
              ),
          ],
        ),
      );
    }

    // Message list (reversed for chat UX — newest at bottom).
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        // Reverse index since list is displayed reversed.
        final message = state.messages[state.messages.length - 1 - index];
        return MessageBubble(message: message);
      },
    );
  }
}

/// Error banner displayed above the chat input.
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: HermesColors.error.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: HermesColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: HermesColors.error,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              // Clear error via provider — handled by chat provider.
            },
            child: const Icon(Icons.close, color: HermesColors.error, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Placeholder input shown while chat is initializing.
class _LoadingInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: HermesColors.surface,
        border: Border(
          top: BorderSide(color: HermesColors.border, width: 0.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: HermesColors.cyan,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Connecting to server...',
            style: TextStyle(color: HermesColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
