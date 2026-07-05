import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// Hermex Material 3 dark theme — from 04_ui_design_system.md.
///
/// Seeds from hermesNavy (#001F5E). Uses ColorScheme.fromSeed for full palette.
/// Only dark theme in MVP.
abstract class AppTheme {
  AppTheme._();

  /// Build the complete Material 3 dark theme.
  static ThemeData build() {
    final colorScheme = ColorScheme.fromSeed(
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

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: HermesColors.dark,
      brightness: Brightness.dark,
      textTheme: HermesTextTheme.buildTextTheme(),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: HermesColors.textPrimary,
        titleTextStyle: HermesTextTheme.buildTextTheme().titleLarge?.copyWith(
              color: HermesColors.textPrimary,
            ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: HermesColors.cyan,
        unselectedItemColor: HermesColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 3,
        selectedLabelStyle:
            HermesTextTheme.buildTextTheme().labelSmall?.copyWith(
                  color: HermesColors.cyan,
                ),
        unselectedLabelStyle:
            HermesTextTheme.buildTextTheme().labelSmall?.copyWith(
                  color: HermesColors.textSecondary,
                ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: HermesColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: HermesColors.border, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HermesColors.dark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: HermesColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: HermesColors.border),
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
        hintStyle: HermesTextTheme.buildTextTheme().bodyLarge?.copyWith(
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
          textStyle: HermesTextTheme.buildTextTheme().labelLarge?.copyWith(
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
        backgroundColor: HermesColors.surface,
        selectedColor: HermesColors.cyan.withValues(alpha: 0.2),
        labelStyle: HermesTextTheme.buildTextTheme().labelMedium?.copyWith(
              color: HermesColors.textPrimary,
            ),
        secondaryLabelStyle:
            HermesTextTheme.buildTextTheme().labelMedium?.copyWith(
              color: HermesColors.cyan,
            ),
        side: const BorderSide(color: HermesColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: HermesColors.border,
        thickness: 0.5,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: HermesColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: HermesColors.surface,
        contentTextStyle:
            HermesTextTheme.buildTextTheme().bodyMedium?.copyWith(
                  color: HermesColors.textPrimary,
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
