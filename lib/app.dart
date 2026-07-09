import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/settings_provider.dart';

/// Root widget — MaterialApp.router with GoRouter, Material 3 theme
/// (light/dark/system), and Arabic locale support.
///
/// DEC-EPIC001-THEME: Converted to ConsumerWidget so themeMode reads from
/// settingsProvider and MaterialApp responds to theme toggle.
class HermexApp extends ConsumerWidget {
  const HermexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeOption = ref.watch(themeModeProvider);

    final themeMode = switch (themeModeOption) {
      ThemeModeOption.light => ThemeMode.light,
      ThemeModeOption.dark => ThemeMode.dark,
      ThemeModeOption.system => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'Hermex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLight(),
      darkTheme: AppTheme.buildDark(),
      themeMode: themeMode,
      routerConfig: appRouter,
      locale: const Locale('en'),
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        // Default to English, support Arabic if available.
        if (locale == null) return const Locale('en');
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('en');
      },
    );
  }
}
