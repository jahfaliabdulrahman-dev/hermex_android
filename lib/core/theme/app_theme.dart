import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// Hermex Material 3 theme — from 04_ui_design_system.md.
///
/// Seeds from hermesNavy (#001F5E). Uses ColorScheme.fromSeed for full palette.
/// DEC-EPIC001-THEME: Split into buildDark / buildLight so themeMode can swap.
abstract class AppTheme {
  AppTheme._();

  /// Build the complete Material 3 dark theme.
  static ThemeData buildDark() {
    final colorScheme = _buildDarkColorScheme();

    return _buildBaseTheme(
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackground: HermesColors.dark,
    );
  }

  /// Build the complete Material 3 light theme.
  static ThemeData buildLight() {
    final colorScheme = _buildLightColorScheme();

    return _buildBaseTheme(
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackground: colorScheme.surface,
    );
  }

  // ─── Color Schemes ─────────────────────────────────────────────────────

  static ColorScheme _buildDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: HermesColors.navy,
      brightness: Brightness.dark,
      primary: HermesColors.navy,
      secondary: HermesColors.cyan,
      surface: HermesColors.surface,
      error: HermesColors.error,
      onPrimary: HermesColors.white,
      onSecondary: HermesColors.dark,
      onSurface: HermesColors.textPrimary,
      onError: HermesColors.white,
    );
  }

  static ColorScheme _buildLightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: HermesColors.navy,
      brightness: Brightness.light,
      primary: HermesColors.navy,
      secondary: HermesColors.cyan,
      error: HermesColors.error,
    );
  }

  // ─── Shared Theme Structure ────────────────────────────────────────────

  /// Builds the shared ThemeData structure that differs only by [colorScheme]
  /// and [brightness]. Uses [colorScheme] properties instead of hardcoded
  /// HermesColors where the value must swap between light/dark.
  static ThemeData _buildBaseTheme({
    required ColorScheme colorScheme,
    required Brightness brightness,
    required Color scaffoldBackground,
  }) {
    final textTheme = HermesTextTheme.buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      brightness: brightness,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: HermesColors.cyan,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.55),
        type: BottomNavigationBarType.fixed,
        elevation: 3,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          color: HermesColors.cyan,
        ),
        unselectedLabelStyle: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: HermesColors.cyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: HermesColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: HermesColors.textDisabled,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HermesColors.cyan,
          foregroundColor: HermesColors.dark,
          disabledBackgroundColor: HermesColors.textDisabled,
          disabledForegroundColor: HermesColors.dark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HermesColors.cyan,
          side: const BorderSide(color: HermesColors.cyan),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 6,
        backgroundColor: HermesColors.cyan,
        foregroundColor: HermesColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: HermesColors.cyan.withValues(alpha: 0.2),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: HermesColors.cyan,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.5,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        // BUG-006: Explicit text styles prevent M3 dark-mode
        // inheritance failures where AlertDialog text renders invisible
        // on the dark HermesColors.surface (#161B22) background.
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.75),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: HermesColors.cyan,
        linearTrackColor: HermesColors.border,
      ),
    );
  }
}
