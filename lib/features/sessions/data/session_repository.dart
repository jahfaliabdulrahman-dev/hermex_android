import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../data/models/cached_session.dart';
import '../../../models/session_summary.dart';

/// Repository for session CRUD operations via API + local Isar cache.
///
/// - Server is the source of truth; cache is read-only fallback.
/// - Cache TTL: 7 days — sessions older than this are considered stale.
/// - Repository owns its own transaction boundaries — no nested writeTxn.
/// - Soft delete on cached records (DEC-034 rule 7).
class SessionRepository {
  final ApiClient _apiClient;
  final Isar _isar;
  static const _cacheTtl = Duration(days: 7);

  SessionRepository({
    required ApiClient apiClient,
    required Isar isar,
  })  : _apiClient = apiClient,
        _isar = isar;

  // ─── API Operations ───

  /// Fetch all sessions from the API.
  /// Returns a list of [SessionSummary] parsed from the server response.
  Future<List<SessionSummary>> getSessions() async {
    debugPrint('=== HERMEX DEBUG: SessionRepository.getSessions ===');

    final data = await _apiClient.get(ApiEndpoints.sessions);

    // The API may return a list directly or wrap it in a 'sessions' key.
    final List<dynamic> rawList = _extractListFromResponse(data);

    final sessions = rawList
        .map((json) => SessionSummary.fromJson(json as Map<String, dynamic>))
        .toList();

    debugPrint(
        '=== HERMEX DEBUG: SessionRepository.getSessions — got ${sessions.length} sessions ===');

    // Cache to Isar.
    await _cacheSessions(sessions);

    return sessions;
  }

  /// Fetch a single session by ID from the API.
  Future<SessionSummary> getSession(String id) async {
    debugPrint('=== HERMEX DEBUG: SessionRepository.getSession — id=$id ===');

    final data = await _apiClient.get(ApiEndpoints.sessionById(id));
    final sessionJson = _extractSessionFromResponse(data);
    return SessionSummary.fromJson(sessionJson);
  }

  /// Create a new session on the server.
  Future<SessionSummary> createSession({String? title}) async {
    debugPrint(
        '=== HERMEX DEBUG: SessionRepository.createSession — title=$title ===');

    final body = <String, dynamic>{};
    if (title != null && title.isNotEmpty) {
      body['title'] = title;
    }

    final data = await _apiClient.post(ApiEndpoints.sessions, data: body);
    final sessionJson = _extractSessionFromResponse(data);
    return SessionSummary.fromJson(sessionJson);
  }

  /// Update session properties (title, pinned, archived) on the server.
  Future<SessionSummary> updateSession(
    String id, {
    String? title,
    bool? isPinned,
    bool? isArchived,
  }) async {
    debugPrint('=== HERMEX DEBUG: SessionRepository.updateSession — id=$id ===');

    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (isPinned != null) body['is_pinned'] = isPinned;
    if (isArchived != null) body['is_archived'] = isArchived;

    final data =
        await _apiClient.put(ApiEndpoints.sessionById(id), data: body);
    final sessionJson = _extractSessionFromResponse(data);
    return SessionSummary.fromJson(sessionJson);
  }

  /// Delete a session on the server.
  Future<void> deleteSession(String id) async {
    debugPrint(
        '=== HERMEX DEBUG: SessionRepository.deleteSession — id=$id ===');

    await _apiClient.delete(ApiEndpoints.sessionById(id));

    // Remove from local cache.
    await _removeCachedSession(id);
  }

  /// Fork a session on the server.
  Future<SessionSummary> forkSession(String id) async {
    debugPrint(
        '=== HERMEX DEBUG: SessionRepository.forkSession — id=$id ===');

    final data =
        await _apiClient.post('${ApiEndpoints.sessionById(id)}/fork');
    final sessionJson = _extractSessionFromResponse(data);
    return SessionSummary.fromJson(sessionJson);
  }

  // ─── Cache Operations ───

  /// Cache a list of sessions locally.
  /// Uses Isar writeTxn for atomicity — this repository OWNS the transaction.
  Future<void> _cacheSessions(List<SessionSummary> sessions) async {
    debugPrint(
        '=== HERMEX DEBUG: SessionRepository._cacheSessions — caching ${sessions.length} sessions ===');

    final now = DateTime.now();

    await _isar.writeTxn(() async {
      for (final session in sessions) {
        final cached = CachedSession(
          sessionId: session.id,
          serverId: _apiClient.dio.options.baseUrl, // Use server URL as foreign key
          title: session.title,
          modelName: session.modelName,
          messageCount: session.messageCount,
          lastActivity: session.lastActivity ?? session.createdAt ?? now,
          isPinned: session.isPinned,
          isArchived: session.isArchived,
          cachedAt: now,
          isDeleted: false,
          deletedAt: null,
        );

        await _isar.cachedSessions.put(cached);
      }
    });
  }

  /// Remove a cached session by server session ID.
  Future<void> _removeCachedSession(String sessionId) async {
    debugPrint(
        '=== HERMEX DEBUG: SessionRepository._removeCachedSession — sessionId=$sessionId ===');

    await _isar.writeTxn(() async {
      final cached = await _isar.cachedSessions
          .filter()
          .sessionIdEqualTo(sessionId)
          .findFirst();

      if (cached != null) {
        cached.isDeleted = true;
        cached.deletedAt = DateTime.now();
        await _isar.cachedSessions.put(cached);
      }
    });
  }

  /// Get sessions from local cache (offline fallback).
  /// Filters out soft-deleted and stale (> 7 days) entries.
  Future<List<CachedSession>> getCachedSessions({
    String? serverId,
  }) async {
    debugPrint(
        '=== HERMEX DEBUG: SessionRepository.getCachedSessions — serverId=$serverId ===');

    final staleThreshold = DateTime.now().subtract(_cacheTtl);

    var query = _isar.cachedSessions
        .filter()
        .isDeletedEqualTo(false)
        .cachedAtGreaterThan(staleThreshold);

    if (serverId != null) {
      query = query.and().serverIdEqualTo(serverId);
    }

    final sessions = await query.sortByLastActivityDesc().findAll();

    debugPrint(
        '=== HERMEX DEBUG: SessionRepository.getCachedSessions — found ${sessions.length} cached sessions ===');

    return sessions;
  }

  /// Check if the cache has any valid (non-stale, non-deleted) entries.
  Future<bool> hasCachedSessions({String? serverId}) async {
    final cached = await getCachedSessions(serverId: serverId);
    return cached.isNotEmpty;
  }

  /// Clear all cached sessions for a server ID (hard delete from Isar).
  /// Used when switching servers or disconnecting.
  Future<void> clearCache({String? serverId}) async {
    debugPrint(
        '=== HERMEX DEBUG: SessionRepository.clearCache — serverId=$serverId ===');

    await _isar.writeTxn(() async {
      if (serverId != null) {
        await _isar.cachedSessions
            .filter()
            .serverIdEqualTo(serverId)
            .deleteAll();
      } else {
        await _isar.cachedSessions.clear();
      }
    });
  }

  // ─── API Response Helpers ───

  /// Extract a list from various API response shapes.
  List<dynamic> _extractListFromResponse(Map<String, dynamic> data) {
    if (data.containsKey('sessions')) {
      return data['sessions'] as List<dynamic>;
    }
    if (data.containsKey('data')) {
      return data['data'] as List<dynamic>;
    }
    final results = data['results'] ?? data['items'];
    if (results is List) {
      return results;
    }
    if (data.isNotEmpty) {
      final listValues = data.values.whereType<List>();
      if (listValues.isNotEmpty) {
        return listValues.first;
      }
    }
    return <dynamic>[];
  }

  /// Extract a single session map from various API response shapes.
  Map<String, dynamic> _extractSessionFromResponse(
      Map<String, dynamic> data) {
    if (data.containsKey('session')) {
      return data['session'] as Map<String, dynamic>;
    }
    if (data.containsKey('data')) {
      return data['data'] as Map<String, dynamic>;
    }
    return data;
  }
}
