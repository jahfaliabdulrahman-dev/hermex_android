import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../models/model_info.dart';
import 'model_selector.dart';

/// Chat input bar — multi-line text field, send button, model selector trigger,
/// and attachment placeholder.
///
/// Supports:
/// - Multi-line text input with auto-expand up to 6 lines
/// - Send button (disabled when input is empty or streaming)
/// - Model selector trigger (shows current model name)
/// - Attachment button (placeholder for future)
/// - RTL support for Arabic text input
class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isStreaming;
  final String? selectedModelId;
  final List<ModelInfo> availableModels;
  final VoidCallback onSend;
  final ValueChanged<String> onModelSelected;

  const ChatInput({
    super.key,
    required this.controller,
    required this.isStreaming,
    required this.selectedModelId,
    required this.availableModels,
    required this.onSend,
    required this.onModelSelected,
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
          // ─── Row 1: Model selector + attachment placeholder ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                // Model selector button.
                _ModelButton(
                  selectedModelId: selectedModelId,
                  models: availableModels,
                  onModelSelected: onModelSelected,
                ),
                const Spacer(),

                // Attachment button (placeholder).
                IconButton(
                  icon: const Icon(Icons.attach_file_outlined, size: 20),
                  color: HermesColors.textDisabled,
                  onPressed: null, // Future feature.
                  tooltip: 'Attach file (coming soon)',
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

/// Compact button showing the currently selected model name.
/// Tapping opens the [ModelSelector] bottom sheet.
class _ModelButton extends StatelessWidget {
  final String? selectedModelId;
  final List<ModelInfo> models;
  final ValueChanged<String> onModelSelected;

  const _ModelButton({
    required this.selectedModelId,
    required this.models,
    required this.onModelSelected,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = selectedModelId ?? 'Select model';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: models.isNotEmpty
            ? () => ModelSelector.show(
                  context,
                  models: models,
                  selectedModelId: selectedModelId,
                  onModelSelected: onModelSelected,
                )
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: HermesColors.navy.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: HermesColors.border,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.psychology_outlined,
                size: 16,
                color: HermesColors.cyan,
              ),
              const SizedBox(width: 6),
              Text(
                displayName,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: HermesColors.cyan,
                    ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: HermesColors.cyan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
