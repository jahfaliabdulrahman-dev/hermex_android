import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hermex_android/core/storage/preferences.dart';
import 'package:hermex_android/features/settings/providers/settings_provider.dart';

void main() {
  group('SettingsState — copyWith', () {
    test('updates themeMode', () {
      const state = SettingsState();
      final updated = state.copyWith(themeMode: ThemeModeOption.light);

      expect(updated.themeMode, ThemeModeOption.light);
      expect(state.themeMode, ThemeModeOption.dark); // Original unchanged
    });

    test('clearDefaultModel sets to null', () {
      final state = SettingsState(defaultModel: 'deepseek-v4-pro');
      final updated = state.copyWith(clearDefaultModel: true);

      expect(updated.defaultModel, isNull);
    });

    test('clearDefaultServerId sets to null', () {
      final state = SettingsState(defaultServerId: 'server-1');
      final updated = state.copyWith(clearDefaultServerId: true);

      expect(updated.defaultServerId, isNull);
    });
  });

  group('ThemeModeOption — displayName', () {
    test('system display name', () {
      expect(ThemeModeOption.system.displayName, 'System');
    });

    test('dark display name', () {
      expect(ThemeModeOption.dark.displayName, 'Dark');
    });

    test('light display name', () {
      expect(ThemeModeOption.light.displayName, 'Light');
    });
  });

  group('SettingsNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(AppPreferences(prefs)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state reads from preferences (empty = system)', () {
      final state = container.read(settingsProvider);

      // SharedPreferences returns 'system' when no value stored.
      expect(state.themeMode, ThemeModeOption.system);
      expect(state.defaultModel, isNull);
      expect(state.defaultServerId, isNull);
    });

    test('themeModeProvider returns theme mode from settings', () {
      final mode = container.read(themeModeProvider);
      expect(mode, ThemeModeOption.system); // Default from prefs
    });

    test('setThemeMode updates state', () async {
      await container.read(settingsProvider.notifier).setThemeMode(ThemeModeOption.light);

      final state = container.read(settingsProvider);
      expect(state.themeMode, ThemeModeOption.light);
    });

    test('setDefaultModel updates state', () async {
      await container
          .read(settingsProvider.notifier)
          .setDefaultModel('deepseek-v4-pro');

      final state = container.read(settingsProvider);
      expect(state.defaultModel, 'deepseek-v4-pro');
      expect(container.read(defaultModelProvider), 'deepseek-v4-pro');
    });

    test('setDefaultModel with empty string clears it', () async {
      await container
          .read(settingsProvider.notifier)
          .setDefaultModel('deepseek-v4-pro');
      await container.read(settingsProvider.notifier).setDefaultModel('');

      final state = container.read(settingsProvider);
      expect(state.defaultModel, isNull);
    });

    test('setDefaultModel with null clears it', () async {
      await container
          .read(settingsProvider.notifier)
          .setDefaultModel('deepseek-v4-pro');
      await container.read(settingsProvider.notifier).setDefaultModel(null);

      final state = container.read(settingsProvider);
      expect(state.defaultModel, isNull);
    });

    test('settings loads persisted theme from SharedPreferences', () async {
      // Set up prefs with a different theme
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', 'light');

      final container2 = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(AppPreferences(prefs)),
        ],
      );

      final state = container2.read(settingsProvider);
      expect(state.themeMode, ThemeModeOption.light);

      container2.dispose();
    });

    test('settings loads persisted model from SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_model', 'gpt-4');

      final container2 = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(AppPreferences(prefs)),
        ],
      );

      final state = container2.read(settingsProvider);
      expect(state.defaultModel, 'gpt-4');

      container2.dispose();
    });
  });
}
