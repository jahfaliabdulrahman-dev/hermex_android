import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hermex typography tokens — from 04_ui_design_system.md §2.
///
/// Uses Inter for body/headlines and JetBrains Mono for code.
/// All styles accessed via [HermesTextTheme].
abstract class HermesTextTheme {
  HermesTextTheme._();

  /// Build a Material 3 TextTheme using the Hermes-approved font families.
  static TextTheme buildTextTheme() {
    final inter = GoogleFonts.interTextTheme();

    return inter.copyWith(
      // ─── Headlines (Inter) ───
      headlineLarge: inter.headlineLarge?.copyWith(
        fontSize: 32,
        height: 40 / 32,
        letterSpacing: -0.5,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: inter.headlineMedium?.copyWith(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: inter.headlineSmall?.copyWith(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
      ),

      // ─── Titles (Inter) ───
      titleLarge: inter.titleLarge?.copyWith(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: 0.15,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: inter.titleSmall?.copyWith(
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w500,
      ),

      // ─── Body (Inter) ───
      bodyLarge: inter.bodyLarge?.copyWith(
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: inter.bodyMedium?.copyWith(
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.25,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: inter.bodySmall?.copyWith(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w400,
      ),

      // ─── Labels (Inter) ───
      labelLarge: inter.labelLarge?.copyWith(
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: inter.labelMedium?.copyWith(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: inter.labelSmall?.copyWith(
        fontSize: 11,
        height: 16 / 11,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// Monospace code style — JetBrains Mono, 13sp, 20 height.
  static TextStyle get code => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        height: 20 / 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      );
}
