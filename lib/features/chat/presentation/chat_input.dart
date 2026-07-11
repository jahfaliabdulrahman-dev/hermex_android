import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// Chat input bar — multi-line text field and send button.
///
/// Supports:
/// - Multi-line text input with auto-expand up to 6 lines
/// - Send button (disabled when input is empty or streaming)
/// - RTL support for Arabic text input
class ChatInput extends StatelessWidget {
 final TextEditingController controller;
 final bool isStreaming;
 final VoidCallback onSend;

 const ChatInput({
 super.key,
 required this.controller,
 required this.isStreaming,
 required this.onSend,
 });

 @override
 Widget build(BuildContext context) {
 final canSend = controller.text.trim().isNotEmpty && !isStreaming;

 return Container(
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.surface,
 border: Border(
 top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
 ),
 ),
 padding: EdgeInsets.only(
 left: 8,
 right: 4,
 top: 8,
 bottom: MediaQuery.of(context).padding.bottom + 8,
 ),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 // ─── Text input + send/stop ───
 Row(
 crossAxisAlignment: CrossAxisAlignment.end,
 children: [
 // Multi-line text input.
 Expanded(
 child: TextField(
 controller: controller,
 minLines: 1,
 maxLines: 6,
 textInputAction: TextInputAction.newline,
 textCapitalization: TextCapitalization.sentences,
 textDirection: _detectTextDirection(controller.text),
 onChanged: (_) =>
 (context as Element).markNeedsBuild(),
 onSubmitted: canSend ? (_) => onSend() : null,
 style: Theme.of(context).textTheme.bodyLarge?.copyWith(
 color: Theme.of(context).colorScheme.onSurface,
 ),
 decoration: InputDecoration(
 hintText: 'Type a message...',
 hintStyle:
 Theme.of(context).textTheme.bodyLarge?.copyWith(
 color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
 ),
 filled: true,
 fillColor: Theme.of(context).colorScheme.surface,
 contentPadding: EdgeInsets.symmetric(
 horizontal: 16,
 vertical: 12,
 ),
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(24),
 borderSide: BorderSide(
 color: Theme.of(context).colorScheme.outlineVariant,
 ),
 ),
 enabledBorder: OutlineInputBorder(
 borderRadius: BorderRadius.circular(24),
 borderSide: BorderSide(
 color: Theme.of(context).colorScheme.outlineVariant,
 ),
 ),
 focusedBorder: OutlineInputBorder(
 borderRadius: BorderRadius.circular(24),
 borderSide: BorderSide(
 color: Theme.of(context).colorScheme.secondary,
 width: 1.5,
 ),
 ),
 ),
 ),
 ),
 const SizedBox(width: 4),

 // Send / Stop button.
 if (isStreaming)
 IconButton(
 icon: Container(
 width: 32,
 height: 32,
 decoration: BoxDecoration(
 color: HermesColors.error,
 shape: BoxShape.circle,
 ),
 child: Icon(
 Icons.stop,
 size: 18,
 color: HermesColors.white,
 ),
 ),
 onPressed: onSend, // onSend triggers stop during streaming.
 tooltip: 'Stop generating',
 )
 else
 IconButton(
 icon: Container(
 width: 40,
 height: 40,
 decoration: BoxDecoration(
 color: canSend ? HermesColors.cyan : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
 shape: BoxShape.circle,
 ),
 child: Icon(
 Icons.arrow_upward,
 size: 20,
 color: canSend
 ? Theme.of(context).colorScheme.onSecondary
 : Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 ),
 onPressed: canSend ? onSend : null,
 tooltip: 'Send message',
 ),
 ],
 ),
 ],
 ),
 );
 }

 /// Detect text direction for RTL (Arabic) support.
 TextDirection _detectTextDirection(String text) {
 if (text.isEmpty) return TextDirection.ltr;
 // Check if the first character is from an RTL script.
 final firstChar = text.trim().characters.first;
 final codeUnit = firstChar.codeUnitAt(0);
 if ((codeUnit >= 0x0600 && codeUnit <= 0x06FF) || // Arabic
 (codeUnit >= 0x0750 && codeUnit <= 0x077F) || // Arabic Supplement
 (codeUnit >= 0xFB50 && codeUnit <= 0xFDFF) || // Arabic Presentation A
 (codeUnit >= 0xFE70 && codeUnit <= 0xFEFF)) {
 // Arabic Presentation B
 return TextDirection.rtl;
 }
 return TextDirection.ltr;
 }
}
