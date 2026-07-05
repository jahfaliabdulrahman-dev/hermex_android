import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget — MaterialApp.router with GoRouter, Material 3 dark theme,
/// and Arabic locale support.
class HermexApp extends StatelessWidget {
  const HermexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hermex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
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
