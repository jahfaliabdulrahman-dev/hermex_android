import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/preferences.dart';
import 'data/datasources/local/isar_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize local persistence before the widget tree.
    final isar = await initIsarDatabase();
    final prefs = await initPreferences();

    runApp(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
          appPreferencesProvider.overrideWithValue(AppPreferences(prefs)),
        ],
        child: const HermexApp(),
      ),
    );
  } catch (e, stack) {
    // ignore: avoid_print — intentional in release for crash diagnostics
    print('FATAL — init failed: $e\n$stack');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Initialization failed.\n\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
