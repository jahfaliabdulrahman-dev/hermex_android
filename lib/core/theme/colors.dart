import 'package:flutter/material.dart';

/// Hermex brand color tokens.
/// Prefer [Theme.of(context).colorScheme] or [HermesThemeTokens].
abstract class HermesColors {
  HermesColors._();
  static const Color navy = Color(0xFF001F5E);
  static const Color cyan = Color(0xFF32C2FF);
  static const Color dark = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color border = Color(0xFF30363D);
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textDisabled = Color(0xFF6E7681);
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFF85149);
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color info = Color(0xFF58A6FF);
  static const Color userBubble = Color(0xFF32C2FF);
  static const Color userBubbleText = Color(0xFF0D1117);
  static const Color agentBubble = Color(0xFF161B22);
  static const Color agentBubbleText = Color(0xFFE6EDF3);
  static const Color codeBlockBg = Color(0xFF0D1117);
  static const Color codeBlockBorder = Color(0xFF30363D);
  // Light theme (WCAG AA 4.5:1)
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F0F5);
  static const Color lightOnSurface = Color(0xFF1A1A2E);
  static const Color lightOnSurfaceVariant = Color(0xFF49454F);
  static const Color lightOutline = Color(0xFF79747E);
  static const Color lightSecondary = Color(0xFF0077A3);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSecondaryContainer = Color(0xFFE0F4FF);
  static const Color lightOnSecondaryContainer = Color(0xFF004D66);
  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFFFDAD6);
  static const Color lightOnErrorContainer = Color(0xFF410002);
  static const Color lightUserBubble = Color(0xFF32C2FF);
  static const Color lightUserBubbleText = Color(0xFF0D1117);
  static const Color lightAgentBubble = Color(0xFFF0F0F5);
  static const Color lightAgentBubbleText = Color(0xFF1A1A2E);
  static const Color lightCodeBlockBg = Color(0xFFF0F0F5);
  static const Color lightCodeBlockBorder = Color(0xFF79747E);
}
