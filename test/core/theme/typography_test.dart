import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermex_android/core/theme/typography.dart';

/// Validates that all TextTheme styles explicitly set fontFamily to 'Inter'
/// and that fontWeight values match the approved design system.
///
/// This test runs in CI — no physical device needed.
/// Physical device verification for variable-font bold rendering
/// (FontWeight.w700 on Inter.ttf) remains tracked as TECH-DEBT-001.
void main() {
  group('HermesTextTheme', () {
    late TextTheme theme;

    setUp(() {
      theme = HermesTextTheme.buildTextTheme();
    });

    test('all 15 TextTheme slots are non-null', () {
      expect(theme.displayLarge, isNotNull);
      expect(theme.displayMedium, isNotNull);
      expect(theme.displaySmall, isNotNull);
      expect(theme.headlineLarge, isNotNull);
      expect(theme.headlineMedium, isNotNull);
      expect(theme.headlineSmall, isNotNull);
      expect(theme.titleLarge, isNotNull);
      expect(theme.titleMedium, isNotNull);
      expect(theme.titleSmall, isNotNull);
      expect(theme.bodyLarge, isNotNull);
      expect(theme.bodyMedium, isNotNull);
      expect(theme.bodySmall, isNotNull);
      expect(theme.labelLarge, isNotNull);
      expect(theme.labelMedium, isNotNull);
      expect(theme.labelSmall, isNotNull);
    });

    group('fontFamily', () {
      test('headlines use Inter', () {
        expect(theme.headlineLarge!.fontFamily, 'Inter');
        expect(theme.headlineMedium!.fontFamily, 'Inter');
        expect(theme.headlineSmall!.fontFamily, 'Inter');
      });

      test('titles use Inter', () {
        expect(theme.titleLarge!.fontFamily, 'Inter');
        expect(theme.titleMedium!.fontFamily, 'Inter');
        expect(theme.titleSmall!.fontFamily, 'Inter');
      });

      test('body styles use Inter', () {
        expect(theme.bodyLarge!.fontFamily, 'Inter');
        expect(theme.bodyMedium!.fontFamily, 'Inter');
        expect(theme.bodySmall!.fontFamily, 'Inter');
      });

      test('labels use Inter', () {
        expect(theme.labelLarge!.fontFamily, 'Inter');
        expect(theme.labelMedium!.fontFamily, 'Inter');
        expect(theme.labelSmall!.fontFamily, 'Inter');
      });
    });

    group('bold weight (w700) verification', () {
      test('headlineLarge is bold (w700)', () {
        expect(theme.headlineLarge!.fontWeight, FontWeight.w700);
      });

      test('w600 weights are semi-bold', () {
        expect(theme.headlineMedium!.fontWeight, FontWeight.w600);
        expect(theme.headlineSmall!.fontWeight, FontWeight.w600);
        expect(theme.titleLarge!.fontWeight, FontWeight.w600);
      });

      test('w500 weights are medium', () {
        expect(theme.titleMedium!.fontWeight, FontWeight.w500);
        expect(theme.titleSmall!.fontWeight, FontWeight.w500);
        expect(theme.labelLarge!.fontWeight, FontWeight.w500);
        expect(theme.labelMedium!.fontWeight, FontWeight.w500);
      });

      test('body styles are regular (w400)', () {
        expect(theme.bodyLarge!.fontWeight, FontWeight.w400);
        expect(theme.bodyMedium!.fontWeight, FontWeight.w400);
        expect(theme.bodySmall!.fontWeight, FontWeight.w400);
        expect(theme.labelSmall!.fontWeight, FontWeight.w400);
      });
    });

    group('code style', () {
      test('uses JetBrains Mono', () {
        expect(HermesTextTheme.code.fontFamily, 'JetBrains Mono');
      });

      test('fontSize is 13', () {
        expect(HermesTextTheme.code.fontSize, 13);
      });
    });
  });
}
