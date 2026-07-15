import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../models/hermes_profile.dart';

/// Repository for HermesProfile CRUD operations on the local Isar database.
///
/// HermesProfile extends flat ServerConfig (stored in secure_storage) with
/// per-profile model and reasoning-effort preferences.
///
/// Repository owns its own transaction boundaries — no nested writeTxn.
/// Anti-Ghost Protocol: all deletions are soft-deletes (isDeleted + deletedAt).
class HermesProfileRepository {
  final Isar _isar;

  HermesProfileRepository({required Isar isar}) : _isar = isar;

  // ─── Create ───

  /// Create a new HermesProfile.
  /// Returns the created profile with auto-increment id.
  Future<HermesProfile> create({
    required String name,
    required String serverId,
    String? defaultModelId,
    String? reasoningEffort,
    int? thinkingBudgetTokens,
    bool isActive = false,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: HermesProfileRepository.create — name=$name, serverId=$serverId ===');
    }

    
    final now = DateTime.now();
    final profile = HermesProfile(
      name: name,
      serverId: serverId,
      defaultModelId: defaultModelId,
      reasoningEffort: reasoningEffort,
      thinkingBudgetTokens: thinkingBudgetTokens,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );

    await _isar.writeTxn(() async {
      // If this profile is active, deactivate all others.
      if (isActive) {
        await _deactivateOtherProfiles(serverId);
      }
      await _isar.hermesProfiles.put(profile);
    });

    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: HermesProfileRepository.create — done: id=${profile.id} ===');
    }
    return profile;
  }

  // ─── Read ───

  /// Get all non-deleted profiles, sorted by name.
  Future<List<HermesProfile>> getAll() async {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: HermesProfileRepository.getAll ===');
    }
    return _isar.hermesProfiles
        .filter()
        .isDeletedEqualTo(false)
        .sortByName()
        .findAll();
  }

  /// Get a profile by its Isar id.
  Future<HermesProfile?> getById(int id) async {
    return _isar.hermesProfiles.get(id);
  }

  /// Get a profile by serverId (FK to ServerConfig).
  Future<HermesProfile?> getByServerId(String serverId) async {
    return _isar.hermesProfiles
        .filter()
        .serverIdEqualTo(serverId)
        .isDeletedEqualTo(false)
        .findFirst();
  }

  /// Get the currently active profile.
  Future<HermesProfile?> getActive() async {
    return _isar.hermesProfiles
        .filter()
        .isActiveEqualTo(true)
        .isDeletedEqualTo(false)
        .findFirst();
  }

  /// Check if a profile exists for a given serverId.
  Future<bool> existsForServer(String serverId) async {
    final count = await _isar.hermesProfiles
        .filter()
        .serverIdEqualTo(serverId)
        .isDeletedEqualTo(false)
        .count();
    return count > 0;
  }

  // ─── Update ───

  /// Update an existing profile's fields.
  /// Only provided (non-null) fields are updated.
  Future<HermesProfile?> update(
    int id, {
    String? name,
    String? defaultModelId,
    String? reasoningEffort,
    int? thinkingBudgetTokens,
    bool? isActive,
    bool clearDefaultModelId = false,
    bool clearReasoningEffort = false,
    bool clearThinkingBudgetTokens = false,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: HermesProfileRepository.update — id=$id ===');
    }

    HermesProfile? updated;
    await _isar.writeTxn(() async {
      final profile = await _isar.hermesProfiles.get(id);
      if (profile == null || profile.isDeleted) return;

      if (name != null) profile.name = name;
      if (clearDefaultModelId) {
        profile.defaultModelId = null;
      } else if (defaultModelId != null) {
        profile.defaultModelId = defaultModelId;
      }
      if (clearReasoningEffort) {
        profile.reasoningEffort = null;
      } else if (reasoningEffort != null) {
        profile.reasoningEffort = reasoningEffort;
      }
      if (clearThinkingBudgetTokens) {
        profile.thinkingBudgetTokens = null;
      } else if (thinkingBudgetTokens != null) {
        profile.thinkingBudgetTokens = thinkingBudgetTokens;
      }
      if (isActive == true) {
        await _deactivateOtherProfiles(profile.serverId);
        profile.isActive = true;
      } else if (isActive == false) {
        profile.isActive = false;
      }

      profile.updatedAt = DateTime.now();
      await _isar.hermesProfiles.put(profile);
      updated = profile;
    });

    return updated;
  }

  /// Set a profile as the active one.
  /// Deactivates all other profiles first (only ONE active at a time).
  Future<void> setActive(int id) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: HermesProfileRepository.setActive — id=$id ===');
    }

    await _isar.writeTxn(() async {
      final profile = await _isar.hermesProfiles.get(id);
      if (profile == null || profile.isDeleted) return;

      // Deactivate all other profiles.
      final others = await _isar.hermesProfiles
          .filter()
          .isActiveEqualTo(true)
          .not().idEqualTo(id)
          .findAll();

      for (final other in others) {
        other.isActive = false;
        other.updatedAt = DateTime.now();
        await _isar.hermesProfiles.put(other);
      }

      profile.isActive = true;
      profile.updatedAt = DateTime.now();
      await _isar.hermesProfiles.put(profile);
    });
  }

  // ─── Delete (SOFT) ───

  /// Soft-delete a profile (isDeleted = true, deletedAt = now).
  /// Per Anti-Ghost Protocol — never hard delete.
  Future<void> softDelete(int id) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: HermesProfileRepository.softDelete — id=$id ===');
    }

    await _isar.writeTxn(() async {
      final profile = await _isar.hermesProfiles.get(id);
      if (profile == null) return;

      profile.isDeleted = true;
      profile.deletedAt = DateTime.now();
      profile.isActive = false;
      profile.updatedAt = DateTime.now();
      await _isar.hermesProfiles.put(profile);
    });
  }

  /// Hard-delete all profiles for a given serverId.
  /// Use with caution — violates Anti-Ghost Protocol except for
  /// "Delete All Data" danger-zone flow (Lead Architect approved).
  Future<void> hardDeleteByServerId(String serverId) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: HermesProfileRepository.hardDeleteByServerId — serverId=$serverId ===');
    }

    await _isar.writeTxn(() async {
      await _isar.hermesProfiles
          .filter()
          .serverIdEqualTo(serverId)
          .deleteAll();
    });
  }

  // ─── Migration ───

  /// Migrate from flat ServerConfig to HermesProfile.
  ///
  /// Call this once after the Isar schema is initialized.
  /// For each existing ServerConfig (from secure_storage), creates a
  /// corresponding HermesProfile with:
  /// - name = server name
  /// - serverId = server id
  /// - isActive = true for the 'default' server
  /// - defaultModelId = null (was never stored in flat ServerConfig)
  ///
  /// Idempotent: skips servers that already have a profile.
  Future<int> migrateFromServerConfigs({
    required List<Map<String, dynamic>> serverConfigs,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: HermesProfileRepository.migrateFromServerConfigs — '
        '${serverConfigs.length} configs ===');
    }

    
    var migrated = 0;

    for (final config in serverConfigs) {
      final serverId = config['id'] as String;
      final exists = await existsForServer(serverId);
      if (exists) continue;

      final name = config['name'] as String? ?? 'Unnamed Server';
      final isDefault = config['isDefault'] as bool? ?? false;

      await create(
        name: name,
        serverId: serverId,
        isActive: isDefault,
      );
      migrated++;
    }

    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: HermesProfileRepository.migrateFromServerConfigs — '
        'migrated $migrated configs ===');
    }
    return migrated;
  }

  /// Ensure a profile exists for a server, creating a default one if needed.
  /// Returns the existing or newly-created profile.
  Future<HermesProfile> ensureProfileForServer({
    required String serverId,
    required String name,
    String? defaultModelId,
  }) async {
    final existing = await getByServerId(serverId);
    if (existing != null) {
      if (!existing.isActive) {
        await setActive(existing.id);
      }
      return existing;
    }

    return create(
      name: name,
      serverId: serverId,
      defaultModelId: defaultModelId,
      isActive: true,
    );
  }

  // ─── Private Helpers ───

  /// Deactivate all active profiles except those matching [keepServerId].
  /// MUST be called within an existing writeTxn — caller owns the boundary.
  Future<void> _deactivateOtherProfiles([String? keepServerId]) async {
    var query = _isar.hermesProfiles.filter().isActiveEqualTo(true);
    if (keepServerId != null) {
      query = query.and().not().serverIdEqualTo(keepServerId);
    }

    final activeOthers = await query.findAll();
    for (final other in activeOthers) {
      other.isActive = false;
      other.updatedAt = DateTime.now();
      await _isar.hermesProfiles.put(other);
    }
  }
}
