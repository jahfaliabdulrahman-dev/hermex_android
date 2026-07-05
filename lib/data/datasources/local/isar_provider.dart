import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/cached_session.dart';
import '../../models/user_preference.dart';

/// Database name constant — centralized, no magic strings.
const String kDatabaseName = 'hermex_cache';

/// Riverpod provider for the Isar instance.
///
/// Must be overridden in ProviderScope with the result of [initIsarDatabase].
/// Throws [StateError] if accessed before initialization.
final isarProvider = Provider<Isar>((ref) {
  final existing = Isar.getInstance(kDatabaseName);
  if (existing != null) return existing;
  throw StateError(
    'Isar not initialized before runApp(). '
    'Call initIsarDatabase() before runApp() and override isarProvider.',
  );
});

/// Initialize Isar database. Call before runApp().
///
/// Uses [Isar.getInstance] to avoid double-open on hot reload.
/// Returns the Isar instance to be injected via ProviderScope override.
Future<Isar> initIsarDatabase() async {
  final dir = await getApplicationDocumentsDirectory();

  final existing = Isar.getInstance(kDatabaseName);
  if (existing != null) return existing;

  final isar = await Isar.open(
    [CachedSessionSchema, UserPreferenceSchema],
    directory: dir.path,
    name: kDatabaseName,
    maxSizeMiB: 32, // Cache-only — small DB
  );

  return isar;
}
