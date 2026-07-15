import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hermex_android/features/connection/presentation/connection_screen.dart';
import 'package:hermex_android/features/connection/providers/connection_provider.dart';
import 'package:hermex_android/features/sessions/presentation/session_list_screen.dart';
import 'package:hermex_android/features/sessions/providers/session_provider.dart';
import 'package:hermex_android/features/sessions/data/session_repository.dart';
import 'package:hermex_android/features/settings/presentation/settings_screen.dart';
import 'package:hermex_android/features/settings/providers/settings_provider.dart';

/// Integration-level navigation flow tests.

GoRouter _testRouter() => GoRouter(
      initialLocation: '/sessions',
      routes: [
        GoRoute(path: '/connection', builder: (c, s) => const ConnectionScreen()),
        GoRoute(path: '/sessions', builder: (c, s) => const SessionListScreen()),
        GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
      ],
    );

Widget _wrap(GoRouter router) {
  return ProviderScope(
    overrides: [
      connectionProvider.overrideWith(() => _TestConnNotifier()),
      sessionListProvider.overrideWith((ref) async => SessionListPage(sessions: [])),
      sessionsNotifierProvider.overrideWith(() => _TestSessionsNotifier()),
      settingsProvider.overrideWith(() => _TestSettingsNotifier(ThemeModeOption.dark)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

class _TestConnNotifier extends ConnectionNotifier {
  @override
  ServerConnectionState build() => const ServerConnectionState();
}

class _TestSessionsNotifier extends SessionsNotifier {
  @override
  SessionsScreenState build() => const SessionsScreenState();
}

class _TestSettingsNotifier extends SettingsNotifier {
  final ThemeModeOption _theme;
  _TestSettingsNotifier(this._theme);
  @override
  SettingsState build() => SettingsState(themeMode: _theme);
}

void main() {
  group('Integration — Navigation', () {
    testWidgets('sessions screen renders', (tester) async {
      final r = _testRouter();
      await tester.pumpWidget(_wrap(r));
      await tester.pumpAndSettle();
      expect(find.text('Sessions'), findsOneWidget);
    });

    testWidgets('navigate sessions → settings', (tester) async {
      final r = _testRouter();
      await tester.pumpWidget(_wrap(r));
      await tester.pumpAndSettle();

      r.go('/settings');
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('navigate settings → sessions', (tester) async {
      final r = _testRouter();
      await tester.pumpWidget(_wrap(r));
      await tester.pumpAndSettle();

      r.go('/settings');
      await tester.pumpAndSettle();
      r.go('/sessions');
      await tester.pumpAndSettle();
      expect(find.text('Sessions'), findsOneWidget);
    });

    testWidgets('navigate to connection screen', (tester) async {
      final r = _testRouter();
      await tester.pumpWidget(_wrap(r));
      await tester.pumpAndSettle();

      r.go('/connection');
      await tester.pumpAndSettle();

      // Connection screen should render its structure
      expect(find.byType(ConnectionScreen), findsOneWidget);
    });

    testWidgets('full cycle: sessions → settings → sessions', (tester) async {
      final r = _testRouter();
      await tester.pumpWidget(_wrap(r));
      await tester.pumpAndSettle();
      expect(find.text('Sessions'), findsOneWidget);

      r.go('/settings');
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      r.go('/sessions');
      await tester.pumpAndSettle();
      expect(find.text('Sessions'), findsOneWidget);
    });
  });
}
