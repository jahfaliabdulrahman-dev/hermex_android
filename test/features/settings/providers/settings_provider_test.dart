import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hermex_android/core/storage/preferences.dart';
import 'package:hermex_android/features/settings/providers/settings_provider.dart';

/// Creates a ProviderContainer with mocked SharedPreferences and
/// appPreferencesProvider override, suitable for SettingsNotifier tests.
Future<ProviderContainer> _createContainer({
  Map<String, Object> initialValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();

  return ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(AppPreferences(prefs)),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  /// T-1: Default value consistency across the theme pipeline.
  /// All three defaults (preferences.dart, settings_provider.dart ctor,
  /// and _themeModeFromString fallback) MUST resolve to dark.
  group('T-1: Theme default consistency', () {
    test('empty storage defaults to dark in AppPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final appPrefs = AppPreferences(prefs);

      expect(appPrefs.themeMode, equals('dark'),
          reason: 'T-1: preferences.dart getter default must be dark');
    });

    test('empty storage defaults to ThemeModeOption.dark in SettingsNotifier',
        () async {
      final container = await _createContainer();

      final state = container.read(settingsProvider);
      expect(state.themeMode, equals(ThemeModeOption.dark),
          reason: 'T-1: SettingsState ctor default must be dark');

      container.dispose();
    });

    test('unknown string falls back to ThemeModeOption.dark in '
        '_themeModeFromString', () async {
      // Seed storage with a garbage value to trigger the fallback path.
      final container = await _createContainer(
        initialValues: {PrefKeys.themeMode: 'garbage_value'},
      );

      final state = container.read(settingsProvider);
      expect(state.themeMode, equals(ThemeModeOption.dark),
          reason: 'T-1: _themeModeFromString fallback must be dark');

      container.dispose();
    });

    test('all three defaults align: prefs getter, notifier build, fallback',
        () async {
      final container = await _createContainer();

      // After build, the notifier reads from prefs → getter default (dark).
      // Since nothing was stored, getter returns 'dark', which maps to
      // ThemeModeOption.dark in _themeModeFromString.
      final state = container.read(settingsProvider);
      expect(state.themeMode, equals(ThemeModeOption.dark));

      // Verify the raw prefs getter also returns 'dark'.
      final prefs = container.read(appPreferencesProvider);
      expect(prefs.themeMode, equals('dark'));

      container.dispose();
    });

    test('deleteAllData resets to dark', () async {
      // Mock flutter_secure_storage channel — not available in unit tests.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'deleteAll') {
            return true;
          }
          return null;
        },
      );

      final container = await _createContainer(
        initialValues: {PrefKeys.themeMode: 'light'},
      );

      // Start with light mode persisted.
      var state = container.read(settingsProvider);
      expect(state.themeMode, equals(ThemeModeOption.light));

      // Nuke everything.
      await container.read(settingsProvider.notifier).deleteAllData();

      state = container.read(settingsProvider);
      expect(state.themeMode, equals(ThemeModeOption.dark),
          reason: 'T-1: deleteAllData must reset to dark');

      container.dispose();
    });
  });

  /// T-2: Race condition fix — rapid toggles must converge to the last
  /// requested mode and persist it correctly.
  group('T-2: Theme toggle race condition', () {
    test('normal setThemeMode persists and updates state', () async {
      final container = await _createContainer();

      await container.read(settingsProvider.notifier).setThemeMode(
        ThemeModeOption.light,
      );

      final state = container.read(settingsProvider);
      expect(state.themeMode, equals(ThemeModeOption.light));

      final prefs = container.read(appPreferencesProvider);
      expect(prefs.themeMode, equals('light'));

      container.dispose();
    });

    test('rapid toggles converge to last requested mode', () async {
      final container = await _createContainer();

      final notifier = container.read(settingsProvider.notifier);

      // Fire 10 rapid toggles WITHOUT awaiting — simulate rapid taps.
      // dark → light → dark → light → dark → light → dark → light → dark →
      // light. Final requested: light.
      final futures = <Future<void>>[];
      futures.add(notifier.setThemeMode(ThemeModeOption.dark));   // 1
      futures.add(notifier.setThemeMode(ThemeModeOption.light));   // 2
      futures.add(notifier.setThemeMode(ThemeModeOption.dark));    // 3
      futures.add(notifier.setThemeMode(ThemeModeOption.light));   // 4
      futures.add(notifier.setThemeMode(ThemeModeOption.dark));    // 5
      futures.add(notifier.setThemeMode(ThemeModeOption.light));   // 6
      futures.add(notifier.setThemeMode(ThemeModeOption.dark));    // 7
      futures.add(notifier.setThemeMode(ThemeModeOption.light));   // 8
      futures.add(notifier.setThemeMode(ThemeModeOption.dark));    // 9
      futures.add(notifier.setThemeMode(ThemeModeOption.light));   // 10 — last wins

      // Wait for all writes to settle.
      await Future.wait(futures);

      // Assert final state and persisted value both match the last request.
      final state = container.read(settingsProvider);
      expect(state.themeMode, equals(ThemeModeOption.light),
          reason: 'T-2: final displayed state must be the last requested mode');

      final prefs = container.read(appPreferencesProvider);
      expect(prefs.themeMode, equals('light'),
          reason: 'T-2: persisted value must match displayed state');

      container.dispose();
    });

    test('last request wins — intermediate values may be skipped', () async {
      final container = await _createContainer();

      final notifier = container.read(settingsProvider.notifier);

      // Start a write, then fire two more requests while write is in flight.
      // Use unawaited to simulate race.
      final future1 = notifier.setThemeMode(ThemeModeOption.light);

      // These arrive while future1 is still writing.
      final future2 = notifier.setThemeMode(ThemeModeOption.system);
      final future3 = notifier.setThemeMode(ThemeModeOption.dark);

      await Future.wait([future1, future2, future3]);

      final state = container.read(settingsProvider);
      expect(state.themeMode, equals(ThemeModeOption.dark),
          reason: 'T-2: last requested mode (dark) must be final state');

      final prefs = container.read(appPreferencesProvider);
      expect(prefs.themeMode, equals('dark'),
          reason: 'T-2: persisted must match last requested mode');

      container.dispose();
    });

    test('persisted value survives restart simulation', () async {
      // Simulate the full lifecycle: set mode → restart app → re-read.
      SharedPreferences.setMockInitialValues({});
      var prefs = await SharedPreferences.getInstance();
      var appPrefs = AppPreferences(prefs);

      final container1 = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(appPrefs),
        ],
      );

      // Set to light.
      await container1
          .read(settingsProvider.notifier)
          .setThemeMode(ThemeModeOption.light);
      expect(container1.read(settingsProvider).themeMode,
          equals(ThemeModeOption.light));

      container1.dispose();

      // Simulate app restart — fresh container, same SharedPreferences.
      final container2 = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(
            AppPreferences(prefs),
          ),
        ],
      );

      expect(container2.read(settingsProvider).themeMode,
          equals(ThemeModeOption.light),
          reason: 'T-2: after restart, theme must match persisted value');

      container2.dispose();
    });
  });
}
