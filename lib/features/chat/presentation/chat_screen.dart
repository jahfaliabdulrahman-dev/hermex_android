import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
 bool _initialized = false;

 @override
 void initState() {
 super.initState();

 // Initialize chat after first frame.
 WidgetsBinding.instance.addPostFrameCallback((_) {
 _initChat();
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

 /// Initialize the chat: connect to server, then optionally load a session.
 Future<void> _initChat() async {
 if (_initialized) return;
 _initialized = true;

 final notifier = ref.read(chatProvider.notifier);
 await notifier.initialize();

 if (!mounted) return;
 final uri = GoRouterState.of(context).uri;
 final sessionId = uri.queryParameters['session'];
 if (sessionId != null && sessionId.isNotEmpty) {
 final title = uri.queryParameters['title'];
 final modelName = uri.queryParameters['model'];
 await notifier.loadHistory(
 sessionId,
 title: title,
 modelName: modelName,
 );
 }
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
 final text = _textController.text.trim();
 if (text.isEmpty) return;

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

 @override
 Widget build(BuildContext context) {
 final state = ref.watch(chatProvider);

 return Scaffold(
 appBar: AppBar(
 title: _buildAppBarTitle(state),
 actions: [
 // New chat button.
 IconButton(
 icon: const Icon(Icons.add_comment_outlined),
 tooltip: 'New Chat',
 onPressed: () {
 _textController.clear();
 _initialized = false;
 ref.read(chatProvider.notifier).startNewChat();
 WidgetsBinding.instance.addPostFrameCallback((_) {
 _initialized = false;
 _initChat();
 });
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
 onSend: _handleSend,
 )
 else
 _LoadingInput(),
 ],
 ),

 // ─── Scroll to Bottom FAB ───
 floatingActionButton: _showScrollFab
 ? FloatingActionButton.small(
 onPressed: _scrollToBottom,
 backgroundColor: Theme.of(context).colorScheme.surface,
 child: const Icon(Icons.arrow_downward, color: HermesColors.cyan),
 )
 : null,
 );
 }

 /// Build the AppBar title with session context.
 Widget _buildAppBarTitle(ChatState state) {
 final hasSession = state.sessionId != null;
 final title = state.sessionTitle;

 if (hasSession && title != null && title.isNotEmpty) {
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisSize: MainAxisSize.min,
 children: [
 Text(
 title,
 style: Theme.of(context).textTheme.titleSmall?.copyWith(
 color: Theme.of(context).colorScheme.onSurface,
 fontWeight: FontWeight.w600,
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 if (state.sessionModelName != null &&
 state.sessionModelName!.isNotEmpty)
 Text(
 state.sessionModelName!,
 style: Theme.of(context).textTheme.bodySmall?.copyWith(
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 ],
 );
 }

 if (hasSession) {
 return Text(
 'Chat',
 style: Theme.of(context).textTheme.titleSmall?.copyWith(
 color: Theme.of(context).colorScheme.onSurface,
 fontWeight: FontWeight.w600,
 ),
 );
 }

 return Text(
 'Hermes Chat',
 style: Theme.of(context).textTheme.titleSmall?.copyWith(
 color: Theme.of(context).colorScheme.onSurface,
 fontWeight: FontWeight.w600,
 ),
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
 color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38).withValues(alpha: 0.5),
 ),
 SizedBox(height: 16),
 Text(
 'Start a conversation with Hermes',
 style: Theme.of(context).textTheme.titleMedium?.copyWith(
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 ),
 SizedBox(height: 8),
 if (state.availableModels.isNotEmpty)
 Text(
 'Using ${state.selectedModelId ?? "default model"}',
 style: Theme.of(context).textTheme.bodySmall?.copyWith(
 color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
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
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.surface,
 border: Border(
 top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
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
 style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
 ),
 ],
 ),
 );
 }
}
