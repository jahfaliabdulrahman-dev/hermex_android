import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/markdown_renderer.dart';
import '../../../models/chat_message.dart';

/// Renders a single [ChatMessage] as a styled bubble.
///
/// Bubble styles by role:
/// - **user**: right-aligned, cyan (#32C2FF) background, dark text
/// - **assistant**: left-aligned, surface (#161B22) background, rendered markdown
/// - **tool**: compact, dimmed, inline with tool status
/// - **system**: centered, dimmed, italic
///
/// Long-press on any bubble copies the content to clipboard.
class MessageBubble extends StatelessWidget {
 final ChatMessage message;

 const MessageBubble({super.key, required this.message});

 @override
 Widget build(BuildContext context) {
 return GestureDetector(
 onLongPress: () {
 if (message.content.isNotEmpty) {
 _copyToClipboard(context, message.content);
 }
 },
 child: Padding(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
 child: switch (message.role) {
 'user' => _UserBubble(message: message),
 'assistant' => _AgentBubble(message: message),
 'tool' => _ToolBubble(message: message),
 _ => _SystemBubble(message: message),
 },
 ),
 );
 }
}

/// Copies [content] to clipboard and shows a SnackBar confirmation.
void _copyToClipboard(BuildContext context, String content) {
 Clipboard.setData(ClipboardData(text: content));
 ScaffoldMessenger.of(context).showSnackBar(
 const SnackBar(
 content: Text('Copied to clipboard'),
 duration: Duration(seconds: 1),
 ),
 );
}

// ─── User Bubble ─────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
 final ChatMessage message;

 const _UserBubble({required this.message});

 @override
 Widget build(BuildContext context) {
 return Row(
 mainAxisAlignment: MainAxisAlignment.end,
 crossAxisAlignment: CrossAxisAlignment.end,
 children: [
 Flexible(
 flex: 3,
 child: Container(
 constraints: const BoxConstraints(maxWidth: 400),
 margin: const EdgeInsets.only(left: 64),
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
 decoration: BoxDecoration(
 color: HermesColors.userBubble,
 borderRadius: const BorderRadius.only(
 topLeft: Radius.circular(16),
 topRight: Radius.circular(16),
 bottomLeft: Radius.circular(16),
 bottomRight: Radius.circular(4),
 ),
 ),
 child: Column(
     crossAxisAlignment: CrossAxisAlignment.end,
     mainAxisSize: MainAxisSize.min,
     children: [
       Text(
         message.content,
         softWrap: true,
         overflow: TextOverflow.ellipsis,
         style: Theme.of(context).textTheme.bodyLarge?.copyWith(
           color: HermesColors.userBubbleText,
         ),
       ),
       const SizedBox(height: 4),
       _TimestampLabel(timestamp: message.timestamp),
     ],
 ),
 ),
 ),
 ],
 );
 }
}

// ─── Agent Bubble ────────────────────────────────────────────────────────

class _AgentBubble extends StatelessWidget {
 final ChatMessage message;

 const _AgentBubble({required this.message});

 @override
 Widget build(BuildContext context) {
 return Row(
 mainAxisAlignment: MainAxisAlignment.start,
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Agent avatar.
 Padding(
 padding: const EdgeInsets.only(top: 4, right: 8),
 child: CircleAvatar(
 radius: 14,
 backgroundColor: HermesColors.navy,
 child: Text(
 'H',
 style: Theme.of(context).textTheme.labelMedium?.copyWith(
 color: HermesColors.cyan,
 fontWeight: FontWeight.bold,
 ),
 ),
 ),
 ),
 Flexible(
 flex: 3,
 child: Container(
 constraints: const BoxConstraints(maxWidth: 400),
 margin: const EdgeInsets.only(right: 64),
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
 decoration: BoxDecoration(
   color: Theme.of(context).colorScheme.surfaceContainerHighest,
 borderRadius: BorderRadius.only(
 topLeft: Radius.circular(4),
 topRight: Radius.circular(16),
 bottomLeft: Radius.circular(16),
 bottomRight: Radius.circular(16),
 ),
 border: Border.all(
 color: Theme.of(context).colorScheme.outlineVariant,
 width: 0.5,
 ),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Copy button header — copies entire agent response at once.
 if (message.content.isNotEmpty)
 Row(
 mainAxisAlignment: MainAxisAlignment.end,
 children: [
 IconButton(
 icon: Icon(Icons.copy, size: 14),
 color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
 onPressed: () =>
 _copyToClipboard(context, message.content),
 visualDensity: VisualDensity.compact,
 tooltip: 'Copy',
 padding: EdgeInsets.zero,
 constraints: const BoxConstraints(
 minWidth: 24,
 minHeight: 24,
 ),
 ),
 ],
 ),
 if (message.content.isNotEmpty)
 HermesMarkdown(data: message.content),
 if (message.isStreaming)
 Padding(
 padding: EdgeInsets.only(top: 8),
 child: _TypingIndicator(),
 ),
 if (message.content.isEmpty && !message.isStreaming)
 Text(
 '(empty response)',
 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
 color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
 fontStyle: FontStyle.italic,
 ),
 ),
 const SizedBox(height: 4),
 _TimestampLabel(timestamp: message.timestamp),
 ],
 ),
 ),
 ),
 ],
 );
 }
}

// ─── Tool Bubble ─────────────────────────────────────────────────────────

class _ToolBubble extends StatelessWidget {
 final ChatMessage message;

 const _ToolBubble({required this.message});

 @override
 Widget build(BuildContext context) {
 return Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Container(
 constraints: const BoxConstraints(maxWidth: 360),
 margin: EdgeInsets.only(left: 48, right: 48),
 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
 width: 0.5,
 ),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 Icons.build_outlined,
 size: 14,
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 SizedBox(width: 8),
 Flexible(
 child: Text(
 message.content,
 style: Theme.of(context).textTheme.bodySmall?.copyWith(
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 ),
 ),
 if (message.toolName != null) ...[
   const SizedBox(width: 8),
   Flexible(
     child: Container(
       padding:
           const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
       decoration: BoxDecoration(
         color: HermesColors.navy.withValues(alpha: 0.6),
         borderRadius: BorderRadius.circular(6),
       ),
       child: Text(
         message.toolName!,
         maxLines: 1,
         overflow: TextOverflow.ellipsis,
         style: Theme.of(context).textTheme.labelSmall?.copyWith(
           color: HermesColors.cyan,
           fontSize: 10,
         ),
       ),
     ),
   ),
 ],
 ],
 ),
 ),
 ],
 );
 }
}

// ─── System Bubble ───────────────────────────────────────────────────────

class _SystemBubble extends StatelessWidget {
 final ChatMessage message;

 const _SystemBubble({required this.message});

 @override
 Widget build(BuildContext context) {
 return Center(
 child: Container(
 constraints: const BoxConstraints(maxWidth: 360),
 margin: EdgeInsets.symmetric(vertical: 8),
 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
 child: Text(
   message.content,
   textAlign: TextAlign.center,
   maxLines: 4,
   overflow: TextOverflow.ellipsis,
   style: Theme.of(context).textTheme.bodySmall?.copyWith(
 color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
 fontStyle: FontStyle.italic,
 ),
 ),
 ),
 );
 }
}

// ─── Timestamp ───────────────────────────────────────────────────────────

class _TimestampLabel extends StatelessWidget {
 final DateTime? timestamp;

 const _TimestampLabel({this.timestamp});

 @override
 Widget build(BuildContext context) {
 if (timestamp == null) return SizedBox.shrink();

 return Text(
 DateFormat('HH:mm').format(timestamp!),
 style: Theme.of(context).textTheme.labelSmall?.copyWith(
 color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
 fontSize: 10,
 ),
 );
 }
}

// ─── Typing Indicator ────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
 const _TypingIndicator();

 @override
 State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
 with SingleTickerProviderStateMixin {
 late final AnimationController _controller;

 @override
 void initState() {
 super.initState();
 _controller = AnimationController(
 vsync: this,
 duration: const Duration(milliseconds: 1200),
 )..repeat();
 }

 @override
 void dispose() {
 _controller.dispose();
 super.dispose();
 }

 @override
 Widget build(BuildContext context) {
 return AnimatedBuilder(
 animation: _controller,
 builder: (context, child) {
 final opacity1 = _dotOpacity(0);
 final opacity2 = _dotOpacity(1);
 final opacity3 = _dotOpacity(2);
 return Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 _Dot(opacity: opacity1),
 const SizedBox(width: 4),
 _Dot(opacity: opacity2),
 const SizedBox(width: 4),
 _Dot(opacity: opacity3),
 ],
 );
 },
 );
 }

 double _dotOpacity(int index) {
 final t = (_controller.value + index / 3) % 1.0;
 if (t < 0.4) return 0.3 + (t / 0.4) * 0.7;
 if (t < 0.7) return 1.0;
 return 1.0 - ((t - 0.7) / 0.3) * 0.7;
 }
}

class _Dot extends StatelessWidget {
 final double opacity;

 const _Dot({required this.opacity});

 @override
 Widget build(BuildContext context) {
 return Opacity(
 opacity: opacity,
 child: Container(
 width: 6,
 height: 6,
 decoration: const BoxDecoration(
 color: HermesColors.cyan,
 shape: BoxShape.circle,
 ),
 ),
 );
 }
}
