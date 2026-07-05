import 'package:isar/isar.dart';

part 'user_preference.g.dart';

/// Persistent user preference stored as key-value pairs in Isar.
///
/// Used for structured preferences that benefit from indexed queries.
/// Simple ephemeral preferences (theme mode, etc.) use SharedPreferences
/// via the preferences.dart wrapper.
@collection
class UserPreference {
  Id id = Isar.autoIncrement;

  /// Preference key (e.g., "default_model", "default_server").
  @Index(unique: true, replace: true)
  late String key;

  /// Preference value as a string.
  late String value;

  /// Last update timestamp.
  late DateTime updatedAt;

  UserPreference({
    this.id = Isar.autoIncrement,
    required this.key,
    required this.value,
    required this.updatedAt,
  });
}
