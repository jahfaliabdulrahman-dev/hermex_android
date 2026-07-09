import 'package:flutter/material.dart';

/// Hermex typography tokens — from 04_ui_design_system.md §2.
///
/// Uses Inter for body/headlines and JetBrains Mono for code.
/// All styles accessed via [HermesTextTheme].
/// Fonts are bundled as static assets in assets/fonts/ — no runtime network fetch.
abstract class HermesTextTheme {
  HermesTextTheme._();

  /// Build a complete Material 3 TextTheme using the bundled Inter variable font.
  ///
  /// All 15 TextTheme styles are explicitly defined to prevent fallback to
  /// system default (Roboto) after google_fonts removal.
  static TextTheme buildTextTheme() {
    return const TextTheme(
      // ─── Display (not customized, must exist to prevent system default) ───
      displayLarge: TextStyle(fontFamily: 'Inter', package: null),
      displayMedium: TextStyle(fontFamily: 'Inter', package: null),
      displaySmall: TextStyle(fontFamily: 'Inter', package: null),

      // ─── Headlines (Inter) ───
      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        package: null,
        fontSize: 32,
        height: 40 / 32,
        letterSpacing: -0.5,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        package: null,
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Inter',
        package: null,
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
      ),

      // ─── Titles (Inter) ───
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        package: null,
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        package: null,
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: 0.15,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        package: null,
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w500,
      ),

      // ─── Body (Inter) ───
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        package: null,
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        package: null,
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.25,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        package: null,
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w400,
      ),

      // ─── Labels (Inter) ───
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        package: null,
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        package: null,
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        package: null,
        fontSize: 11,
        height: 16 / 11,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// Monospace code style — JetBrains Mono, 13sp, 20 height.
  static const TextStyle code = TextStyle(
    fontFamily: 'JetBrains Mono',
    package: null,
    fontSize: 13,
    height: 20 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
}
