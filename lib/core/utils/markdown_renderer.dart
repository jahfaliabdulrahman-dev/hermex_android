import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Pre-configured FlutterMarkdown widget with Hermes code block styling.
/// Uses dark code block background, JetBrains Mono for code, theme-aware colors.
/// DEC-EPIC001-THEME: Text/surface colors now read from colorScheme so
/// light/dark theme switching affects markdown content.
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
    final cs = theme.colorScheme;
    final codeStyle = TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 13,
      height: 20 / 13,
      color: cs.onSurface,
    );

    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyLarge?.copyWith(
          color: cs.onSurface,
          height: 1.6,
        ),
        h1: theme.textTheme.headlineLarge?.copyWith(
          color: cs.onSurface,
        ),
        h2: theme.textTheme.headlineMedium?.copyWith(
          color: cs.onSurface,
        ),
        h3: theme.textTheme.headlineSmall?.copyWith(
          color: cs.onSurface,
        ),
        a: theme.textTheme.bodyLarge?.copyWith(
          color: cs.secondary,
          decoration: TextDecoration.underline,
        ),
        code: codeStyle,
        codeblockDecoration: const BoxDecoration(
          color: Color(0xFF0D1117), // codeBg — always dark
          border: Border(
            left: BorderSide(
              color: Color(0xFF30363D), // codeBlockBorder
              width: 3,
            ),
          ),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquoteDecoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            left: BorderSide(
              color: cs.outline,
              width: 3,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        listBullet: theme.textTheme.bodyLarge?.copyWith(
          color: cs.secondary,
        ),
        tableHead: theme.textTheme.labelLarge?.copyWith(
          color: cs.onPrimary,
        ),
        tableBody: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurface,
        ),
        tableBorder: TableBorder.all(color: cs.outline),
        tableColumnWidth: const FlexColumnWidth(),
        tableCellsPadding: const EdgeInsets.all(8),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: cs.outline),
          ),
        ),
      ),
    );
  }
}
