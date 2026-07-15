import 'package:isar/isar.dart';

part 'hermes_profile.g.dart';

/// First-class Hermes Profile entity — extends flat ServerConfig with
/// per-profile default model and reasoning-effort settings.
///
/// Persisted in Isar (local database) alongside CachedSession and UserPreference.
/// FK to ServerConfig via [serverId] (ServerConfig lives in secure_storage).
///
/// Anti-Ghost Protocol (DEC-034 rule 7): application-level hard deletes are
/// forbidden. Soft-delete via [isDeleted] + [deletedAt].
@collection
class HermesProfile {
  /// Isar auto-increment primary key (internal).
  Id id = Isar.autoIncrement;

  /// Human-readable profile name (e.g., "DeepSeek Prod", "Local Dev").
  @Index()
  late String name;

  /// FK — references ServerConfig.id stored in flutter_secure_storage.
  /// No Isar relationship because ServerConfig is not an Isar entity.
  @Index(unique: true, replace: true)
  late String serverId;

  /// Default model ID for this profile (e.g., "deepseek-v4-pro").
  /// Matches the model `id` field from GET /v1/models.
  /// Null means "use server/provider default".
  String? defaultModelId;

  /// Reasoning effort level for OpenAI-compatible providers.
  ///
  /// Valid values (per OpenAI API spec):
  /// - `null` — omit the parameter entirely (model default)
  /// - `"none"` — no reasoning
  /// - `"low"` — minimal reasoning effort
  /// - `"medium"` — balanced reasoning effort
  /// - `"high"` — maximum reasoning effort
  ///
  /// NOTE: The Hermes Agent API Server v0.18.2 does not validate this
  /// parameter — it passes through to the underlying provider.
  /// Providers that don't support reasoning_effort will silently ignore it.
  String? reasoningEffort;

  /// Optional DeepSeek-style thinking budget in tokens.
  /// When non-null, sends `{"thinking": {"type": "enabled", "budget_tokens": N}}`
  /// alongside `reasoning_effort`. Mutually exclusive with reasoning-only mode.
  int? thinkingBudgetTokens;

  /// Whether this profile is the currently active one.
  /// Only ONE profile should be active at a time — enforced at repository level.
  @Index()
  late bool isActive;

  /// Creation timestamp.
  late DateTime createdAt;

  /// Last modification timestamp.
  late DateTime updatedAt;

  // ─── Soft Delete (DEC-034, Anti-Ghost Protocol) ───

  /// Soft-delete flag. Application-level hard deletes are forbidden.
  @Index()
  late bool isDeleted;

  /// Timestamp when soft-deleted. Null if not deleted.
  DateTime? deletedAt;

  HermesProfile({
    this.id = Isar.autoIncrement,
    required this.name,
    required this.serverId,
    this.defaultModelId,
    this.reasoningEffort,
    this.thinkingBudgetTokens,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  });
}
