import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/connection/providers/connection_provider.dart';
import 'package:hermex_android/features/settings/presentation/settings_screen.dart';
import 'package:hermex_android/features/settings/providers/settings_provider.dart';

Widget _buildTestApp({
  ThemeModeOption themeMode = ThemeModeOption.dark,
}) {
  return ProviderScope(
    overrides: [
      connectionProvider.overrideWith(
        () => _TestConnectionNotifier(),
      ),
      settingsProvider.overrideWith(
        () => _TestSettingsNotifier(themeMode),
      ),
    ],
    child: const MaterialApp(
      home: SettingsScreen(),
    ),
  );
}

class _TestConnectionNotifier extends ConnectionNotifier {
  @override
  ServerConnectionState build() {
    return const ServerConnectionState();
  }
}

class _TestSettingsNotifier extends SettingsNotifier {
  final ThemeModeOption _initialTheme;

  _TestSettingsNotifier(this._initialTheme);

  @override
  SettingsState build() {
    return SettingsState(themeMode: _initialTheme);
  }
}

void main() {
  group('SettingsScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders visible section headers', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Server'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Default Model'), findsOneWidget);
    });

    testWidgets('shows empty server state', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('No saved servers'), findsOneWidget);
    });

    testWidgets('shows theme mode options', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('can scroll to see Danger Zone and About', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Scroll until Danger Zone is visible
      await tester.scrollUntilVisible(
        find.text('Danger Zone'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Danger Zone'), findsOneWidget);

      // Scroll further to About
      await tester.scrollUntilVisible(
        find.text('About'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('delete all data shows confirmation dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Scroll to Danger Zone
      await tester.scrollUntilVisible(
        find.text('Delete All Local Data'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete All Local Data'));
      await tester.pumpAndSettle();

      expect(find.text('Delete All Data?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('shows model text form field', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('agent data section shows Skills, Memory, Insights', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Scroll to Agent Data section
      await tester.scrollUntilVisible(
        find.text('Skills'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Skills'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
    });
  });
}
