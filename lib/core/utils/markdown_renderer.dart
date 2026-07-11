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
      fontFamily: 'JetBrainsMono',
      fontSize: 13,
      height: 20 / 13,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.6,
        ),
        h1: theme.textTheme.headlineLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        h2: theme.textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        h3: theme.textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        a: theme.textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
          decoration: TextDecoration.underline,
        ),
        code: codeStyle,
        codeblockDecoration: BoxDecoration(
          color: HermesThemeTokens.of(context).codeBlockBg,
          border: const Border(
            left: BorderSide(
              color: HermesThemeTokens.of(context).codeBlockBorder,
              width: 3,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquoteDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: const Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 3,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        listBullet: theme.textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ),
        tableHead: theme.textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        tableBody: theme.textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        tableBorder: TableBorder.all(color: Theme.of(context).colorScheme.outline),
        tableColumnWidth: const FlexColumnWidth(),
        tableCellsPadding: const EdgeInsets.all(8),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      ),
    );
  }
}
