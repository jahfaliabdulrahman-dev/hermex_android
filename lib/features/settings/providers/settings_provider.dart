import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/preferences.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../features/connection/providers/connection_provider.dart';
import '../../../models/server_config.dart';

/// Theme mode options.
enum ThemeModeOption {
  system,
  dark,
  light;

  String get displayName {
    switch (this) {
      case ThemeModeOption.system:
        return 'System';
      case ThemeModeOption.dark:
        return 'Dark';
      case ThemeModeOption.light:
        return 'Light';
    }
  }
}

/// Settings state — persisted to SharedPreferences.
class SettingsState {
  final ThemeModeOption themeMode;
  final String? defaultModel;
  final String? defaultServerId;

  const SettingsState({
    this.themeMode = ThemeModeOption.dark,
    this.defaultModel,
    this.defaultServerId,
  });

  SettingsState copyWith({
    ThemeModeOption? themeMode,
    String? defaultModel,
    bool clearDefaultModel = false,
    String? defaultServerId,
    bool clearDefaultServerId = false,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        defaultModel: clearDefaultModel
            ? null
            : (defaultModel ?? this.defaultModel),
        defaultServerId: clearDefaultServerId
            ? null
            : (defaultServerId ?? this.defaultServerId),
      );
}

/// Notifier for application settings management.
///
/// Persists theme mode, default model, and default server to SharedPreferences.
/// Reads initial values from storage on build.
///
/// NOT autoDispose — shared, long-lived controller (DEC-034 rule 2).
class SettingsNotifier extends Notifier<SettingsState> {
  late final AppPreferences _prefs;

  @override
  SettingsState build() {
    _prefs = ref.read(appPreferencesProvider);
    return SettingsState(
      themeMode: _themeModeFromString(_prefs.themeMode),
      defaultModel: _prefs.defaultModel,
      defaultServerId: _prefs.defaultServerId,
    );
  }

  // ─── Theme Mode ───

  Future<void> setThemeMode(ThemeModeOption mode) async {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: SettingsNotifier.setThemeMode — $mode ===');
    }
    await _prefs.setThemeMode(mode.name);
    state = state.copyWith(themeMode: mode);
  }

  // ─── Default Model ───

  Future<void> setDefaultModel(String? modelId) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: SettingsNotifier.setDefaultModel — $modelId ===');
    }
    if (modelId != null && modelId.isNotEmpty) {
      await _prefs.setDefaultModel(modelId);
      state = state.copyWith(defaultModel: modelId);
    } else {
      await _prefs.setDefaultModel('');
      state = state.copyWith(clearDefaultModel: true);
    }
  }

  // ─── Default Server ───

  Future<void> setDefaultServerId(String? serverId) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: SettingsNotifier.setDefaultServerId — $serverId ===');
    }
    if (serverId != null && serverId.isNotEmpty) {
      await _prefs.setDefaultServerId(serverId);
      state = state.copyWith(defaultServerId: serverId);
    } else {
      await _prefs.setDefaultServerId('');
      state = state.copyWith(clearDefaultServerId: true);
    }
  }

  // ─── Danger Zone ───

  /// Delete ALL local data: secure storage + shared preferences.
  /// Also clears the connection provider state.
  Future<void> deleteAllData() async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: SettingsNotifier.deleteAllData ===');
    }

    final secureStorage = SecureStorage();
    await secureStorage.deleteAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Reset connection state.
    ref.read(connectionProvider.notifier).disconnect();

    // Reset settings state to defaults.
    state = const SettingsState();
  }

  // ─── Helpers ───

  ThemeModeOption _themeModeFromString(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeModeOption.dark;
      case 'light':
        return ThemeModeOption.light;
      case 'system':
        return ThemeModeOption.system;
      default:
        return ThemeModeOption.dark; // Hermes brand default
    }
  }
}

// ─── Riverpod Providers ───

/// Settings state notifier. NOT autoDispose.
final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

/// Convenience provider for theme mode only — selective rebuilds.
final themeModeProvider = Provider<ThemeModeOption>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

/// Convenience provider for default model only.
final defaultModelProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).defaultModel;
});

/// Convenience provider for the active server (from connection, not settings).
/// This listens to the connection state for the currently connected server.
final activeServerProvider = Provider<ServerConfig?>((ref) {
  return ref.watch(connectionProvider).activeServer;
});
