import 'package:flutter/material.dart';

/// Hermex brand color tokens — from 04_ui_design_system.md §1.
///
/// Never use raw hex values in widget code.
/// All semantic colors defined here; use via theme extensions.
abstract class HermesColors {
  HermesColors._();

  // ─── Core Palette ───
  static const Color navy = Color(0xFF001F5E);
  static const Color cyan = Color(0xFF32C2FF);
  static const Color dark = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color border = Color(0xFF30363D);

  // ─── Text ───
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  // Boosted from #484F58 → #6E7681 for WCAG AA 4.5:1 contrast on dark bg (#0D1117).
  // #484F58 was ~2.9:1 — failed AA minimum. DEC-EPIC001-THEME.
  static const Color textDisabled = Color(0xFF6E7681);
  static const Color white = Color(0xFFFFFFFF);

  // ─── Semantic ───
  static const Color error = Color(0xFFF85149);
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color info = Color(0xFF58A6FF);

  // ─── Chat-Specific ───
  static const Color userBubble = Color(0xFF32C2FF); // cyan
  static const Color userBubbleText = Color(0xFF0D1117); // dark
  static const Color agentBubble = Color(0xFF161B22); // surface
  static const Color agentBubbleText = Color(0xFFE6EDF3); // textPrimary
  static const Color codeBlockBg = Color(0xFF0D1117); // dark
  static const Color codeBlockBorder = Color(0xFF30363D); // border

  // ─── Light-Mode Palette — 04_ui_design_system.md §1.5 ───
  // DEC-EPIC001-THEME: Light tokens for dual-theme support.
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF0F6FC);
  static const Color lightOnSurface = Color(0xFF1F2328);
  static const Color lightOnSurfaceVariant = Color(0xFF656D76);
  static const Color lightSecondary = Color(0xFF0077A3);
  // #0077A3 is cyanAdapted — #32C2FF adapted for WCAG AA 4.5:1 on light bg.
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightOutline = Color(0xFFD0D7DE);
  static const Color lightOnPrimary = Color(0xFFFFFFFF); // white on navy
}
