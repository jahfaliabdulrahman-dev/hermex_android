import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../theme/colors.dart';

/// Pre-configured FlutterMarkdown widget with Hermes code block styling.
/// Uses dark code block background, JetBrains Mono for code, cyan links.
class HermesMarkdown extends StatelessWidget {
  final String data;
  final bool selectable;

  const HermesMarkdown({
    super.key,
    required this.data,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final codeStyle = const TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 13,
      height: 20 / 13,
    ).copyWith(color: HermesColors.textPrimary);

    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyLarge?.copyWith(
          color: HermesColors.textPrimary,
          height: 1.6,
        ),
        h1: theme.textTheme.headlineLarge?.copyWith(
          color: HermesColors.textPrimary,
        ),
        h2: theme.textTheme.headlineMedium?.copyWith(
          color: HermesColors.textPrimary,
        ),
        h3: theme.textTheme.headlineSmall?.copyWith(
          color: HermesColors.textPrimary,
        ),
        a: theme.textTheme.bodyLarge?.copyWith(
          color: HermesColors.cyan,
          decoration: TextDecoration.underline,
        ),
        code: codeStyle,
        codeblockDecoration: BoxDecoration(
          color: HermesColors.codeBlockBg,
          border: const Border(
            left: BorderSide(
              color: HermesColors.codeBlockBorder,
              width: 3,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquoteDecoration: BoxDecoration(
          color: HermesColors.surface,
          border: const Border(
            left: BorderSide(
              color: HermesColors.border,
              width: 3,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        listBullet: theme.textTheme.bodyLarge?.copyWith(
          color: HermesColors.cyan,
        ),
        tableHead: theme.textTheme.labelLarge?.copyWith(
          color: HermesColors.white,
        ),
        tableBody: theme.textTheme.bodyMedium?.copyWith(
          color: HermesColors.textPrimary,
        ),
        tableBorder: TableBorder.all(color: HermesColors.border),
        tableColumnWidth: const FlexColumnWidth(),
        tableCellsPadding: const EdgeInsets.all(8),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: HermesColors.border),
          ),
        ),
      ),
    );
  }
}
