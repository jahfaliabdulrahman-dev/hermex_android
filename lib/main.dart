import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/preferences.dart';
import 'data/datasources/local/isar_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
}
