import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hermex_android/app.dart';
import 'package:hermex_android/core/storage/preferences.dart';

void main() {
  testWidgets('HermexApp renders without crashing', (WidgetTester tester) async {
    // DEC-EPIC001-THEME: HermexApp is now a ConsumerWidget that reads
    // themeModeProvider → settingsProvider → appPreferencesProvider.
    // Mock SharedPreferences to satisfy the provider chain.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(AppPreferences(prefs)),
        ],
        child: const HermexApp(),
      ),
    );
    // Verify the app renders — MaterialApp.router is present.
    expect(find.byType(HermexApp), findsOneWidget);
  });
}
