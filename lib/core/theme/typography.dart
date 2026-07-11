import 'package:flutter/material.dart';

/// Hermex typography tokens — from 04_ui_design_system.md §2.
///
/// Uses Inter for body/headlines and JetBrains Mono for code.
/// All styles accessed via [HermesTextTheme].
///
/// Static font assets (no runtime fetching — C-1 privacy fix).
abstract class HermesTextTheme {
  HermesTextTheme._();

  /// Build a Material 3 TextTheme using the Hermes-approved font families.
  static TextTheme buildTextTheme() {
    const fontFamily = 'Inter';
    final base = ThemeData.light().textTheme;

    return base.copyWith(
      // ─── Headlines (Inter) ───
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: fontFamily,
        fontSize: 32,
        height: 40 / 32,
        letterSpacing: -0.5,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: fontFamily,
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: fontFamily,
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
      ),

      // ─── Titles (Inter) ───
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: fontFamily,
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: fontFamily,
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: 0.15,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w500,
      ),

      // ─── Body (Inter) ───
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: fontFamily,
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.25,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: fontFamily,
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w400,
      ),

      // ─── Labels (Inter) ───
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: fontFamily,
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontFamily: fontFamily,
        fontSize: 11,
        height: 16 / 11,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// Monospace code style — JetBrains Mono, 13sp, 20 height.
  static TextStyle get code => const TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 13,
        height: 20 / 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      );
}
