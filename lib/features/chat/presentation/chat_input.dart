import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// Chat input bar — multi-line text field, send button, and attachment placeholder.
///
/// Supports:
/// - Multi-line text input with auto-expand up to 6 lines
/// - Send button (disabled when input is empty or streaming)
/// - Attachment button (placeholder for future)
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
        color: HermesColors.surface,
        border: const Border(
          top: BorderSide(color: HermesColors.border, width: 0.5),
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
          // ─── Row: attachment placeholder ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Spacer(),
                // Attachment button (placeholder).
                IconButton(
                  icon: const Icon(Icons.attach_file_outlined, size: 20),
                  color: HermesColors.textDisabled,
                  onPressed: null, // Future feature.
                  tooltip: 'Attach file',
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ─── Row 2: Text input + send/stop ───
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
                        color: HermesColors.textPrimary,
                      ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle:
                        Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: HermesColors.textDisabled,
                            ),
                    filled: true,
                    fillColor: HermesColors.dark,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: HermesColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: HermesColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: HermesColors.cyan,
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
                    child: const Icon(
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
                      color: canSend ? HermesColors.cyan : HermesColors.textDisabled,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward,
                      size: 20,
                      color: canSend
                          ? HermesColors.dark
                          : HermesColors.textSecondary,
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
