import 'package:flutter/material.dart';
import 'colors.dart';
import 'hermes_theme_tokens.dart';
import 'typography.dart';

abstract class AppTheme {
  AppTheme._();

  static ThemeData buildDark() {
    final cs = _buildDarkColorScheme();
    return _buildBase(cs, Brightness.dark, HermesColors.dark, HermesThemeTokens.dark());
  }

  static ThemeData buildLight() {
    final cs = _buildLightColorScheme();
    return _buildBase(cs, Brightness.light, cs.surface, HermesThemeTokens.light());
  }

  static ColorScheme _buildDarkColorScheme() => ColorScheme.fromSeed(
    seedColor: HermesColors.navy, brightness: Brightness.dark,
    primary: HermesColors.navy, secondary: HermesColors.cyan,
    surface: HermesColors.surface, error: HermesColors.error,
    onPrimary: HermesColors.white, onSecondary: HermesColors.dark,
    onSurface: HermesColors.textPrimary, onError: HermesColors.white,
    surfaceContainerHighest: HermesColors.dark, outline: HermesColors.border,
  );

  static ColorScheme _buildLightColorScheme() => ColorScheme.fromSeed(
    seedColor: HermesColors.navy, brightness: Brightness.light,
    primary: HermesColors.navy, onPrimary: HermesColors.white,
    primaryContainer: const Color(0xFFD6E2FF),
    onPrimaryContainer: const Color(0xFF001B4E),
    secondary: HermesColors.lightSecondary,
    onSecondary: HermesColors.lightOnSecondary,
    secondaryContainer: HermesColors.lightSecondaryContainer,
    onSecondaryContainer: HermesColors.lightOnSecondaryContainer,
    tertiary: const Color(0xFF006B5E), onTertiary: HermesColors.white,
    tertiaryContainer: const Color(0xFF7FF8E2),
    onTertiaryContainer: const Color(0xFF00201B),
    surface: HermesColors.lightSurface, onSurface: HermesColors.lightOnSurface,
    surfaceContainerHigh: HermesColors.lightSurfaceVariant,
    surfaceContainerHighest: const Color(0xFFE8E8EE),
    onSurfaceVariant: HermesColors.lightOnSurfaceVariant,
    error: HermesColors.lightError, onError: HermesColors.lightOnError,
    errorContainer: HermesColors.lightErrorContainer,
    onErrorContainer: HermesColors.lightOnErrorContainer,
    outline: HermesColors.lightOutline,
    outlineVariant: const Color(0xFFC4C6D0),
    shadow: Colors.black.withValues(alpha: 0.1),
    scrim: Colors.black.withValues(alpha: 0.3),
  );

  static ThemeData _buildBase(ColorScheme cs, Brightness brightness,
      Color scaffoldBg, HermesThemeTokens tokens) {
    final tt = HermesTextTheme.buildTextTheme();
    final hint = cs.onSurface.withValues(alpha: 0.38);
    return ThemeData(
      useMaterial3: true, colorScheme: cs,
      scaffoldBackgroundColor: scaffoldBg, brightness: brightness,
      textTheme: tt,
      appBarTheme: AppBarTheme(elevation: 0, centerTitle: false,
        backgroundColor: cs.surface, foregroundColor: cs.onSurface,
        titleTextStyle: tt.titleLarge?.copyWith(color: cs.onSurface)),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cs.surface, selectedItemColor: cs.secondary,
        unselectedItemColor: cs.onSurfaceVariant,
        type: BottomNavigationBarType.fixed, elevation: 3,
        selectedLabelStyle: tt.labelSmall?.copyWith(color: cs.secondary),
        unselectedLabelStyle: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
      cardTheme: CardThemeData(elevation: 1, color: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant, width: 0.5))),
      inputDecorationTheme: InputDecorationTheme(filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: cs.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: cs.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: cs.secondary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: cs.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: tt.bodyLarge?.copyWith(color: hint)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: cs.secondary,
          foregroundColor: cs.onSecondary,
          disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: hint,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600))),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: cs.secondary,
          side: BorderSide(color: cs.secondary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(elevation: 6,
        backgroundColor: cs.secondary, foregroundColor: cs.onSecondary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)))),
      chipTheme: ChipThemeData(backgroundColor: cs.surface,
        selectedColor: cs.secondary.withValues(alpha: 0.2),
        labelStyle: tt.labelMedium?.copyWith(color: cs.onSurface),
        secondaryLabelStyle: tt.labelMedium?.copyWith(color: cs.secondary),
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      dividerTheme: DividerThemeData(color: cs.outlineVariant,
        thickness: 0.5, space: 1),
      dialogTheme: DialogThemeData(backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: tt.headlineSmall?.copyWith(color: cs.onSurface),
        contentTextStyle: tt.bodyMedium?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.75))),
      snackBarTheme: SnackBarThemeData(backgroundColor: cs.inverseSurface,
        contentTextStyle: tt.bodyMedium?.copyWith(color: cs.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.secondary, linearTrackColor: cs.outlineVariant),
      extensions: [tokens],
    );
  }
}
