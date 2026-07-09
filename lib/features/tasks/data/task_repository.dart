import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../models/cron_job.dart';

/// Repository for CronJob CRUD and action operations against Hermes Agent API.
///
/// Talks to the Hermes Agent API Server via [ApiClient].
/// Does NOT own Isar persistence — this is a server-backed feature.
/// Repository owns its own transaction boundaries — no nested writeTxn.
class TaskRepository {
  final ApiClient _apiClient;

  TaskRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ─── List ───

  /// Fetch all cron jobs from the server.
  /// Parses the JSON response safely — invalid entries are skipped.
  Future<List<CronJob>> getAll() async {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: TaskRepository.getAll ===');
    }
    try {
      final response = await _apiClient.get(ApiEndpoints.jobs);
      final jobsList = response['jobs'] as List<dynamic>? ?? [];
      return jobsList
          .map((json) {
            try {
              return CronJob.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              if (kDebugMode) {
                debugPrint(
                  '=== HERMEX DEBUG: TaskRepository.getAll — skipping malformed job: $e ===');
              }
              return null;
            }
          })
          .whereType<CronJob>()
          .toList();
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskRepository.getAll DioException — ${e.type}: ${e.message} ===');
      }
      throw _classifyError(e);
    }
  }

  /// Fetch a single cron job by ID.
  /// API wraps response in {"job": {...}} — must unwrap.
  Future<CronJob> getById(String id) async {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: TaskRepository.getById — id=$id ===');
    }
    try {
      final response = await _apiClient.get(ApiEndpoints.jobById(id));
      // DEC-EPIC001-DEPCHECK: API returns {"job": {...}}, not bare job object.
      final jobData = response['job'] as Map<String, dynamic>;
      return CronJob.fromJson(jobData);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskRepository.getById DioException — ${e.type}: ${e.message} ===');
      }
      throw _classifyError(e);
    }
  }

  // ─── Create ───

  /// Create a new cron job on the server.
  /// Returns the created [CronJob] with server-assigned ID.
  Future<CronJob> create({
    required String prompt,
    required String schedule,
    String? name,
    List<String>? skills,
    String? modelProvider,
    String? modelName,
    String? deliver,
  }) async {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: TaskRepository.create — schedule=$schedule ===');
    }
    try {
      final body = <String, dynamic>{
        'prompt': prompt,
        'schedule': schedule,
      };
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (skills != null && skills.isNotEmpty) body['skills'] = skills;
      if (modelProvider != null) body['model_provider'] = modelProvider;
      if (modelName != null) body['model_name'] = modelName;
      if (deliver != null) body['deliver'] = deliver;

      final response = await _apiClient.post(ApiEndpoints.jobs, data: body);
      // DEC-EPIC001-DEPCHECK: POST returns {"job": {...}}, not bare job object.
      final jobData = response['job'] as Map<String, dynamic>;
      return CronJob.fromJson(jobData);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskRepository.create DioException — ${e.type}: ${e.message} ===');
      }
      throw _classifyError(e);
    }
  }

  // ─── Update ───

  /// Update an existing cron job.
  /// Only sends the fields that are provided (partial update).
  ///
  /// DEC-EPIC001-DEPCHECK: Uses PATCH (PUT returns 405 on Hermes API Server v0.18.2).
  Future<CronJob> update({
    required String id,
    String? prompt,
    String? schedule,
    String? name,
    List<String>? skills,
    String? modelProvider,
    String? modelName,
    String? deliver,
    bool? paused,
  }) async {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: TaskRepository.update — id=$id ===');
    }
    try {
      final body = <String, dynamic>{};
      if (prompt != null) body['prompt'] = prompt;
      if (schedule != null) body['schedule'] = schedule;
      if (name != null) body['name'] = name;
      if (skills != null) body['skills'] = skills;
      if (modelProvider != null) body['model_provider'] = modelProvider;
      if (modelName != null) body['model_name'] = modelName;
      if (deliver != null) body['deliver'] = deliver;
      if (paused != null) body['paused'] = paused;

      final response =
          await _apiClient.patch(ApiEndpoints.jobById(id), data: body);
      // DEC-EPIC001-DEPCHECK: PATCH returns {"job": {...}}, not bare job object.
      final jobData = response['job'] as Map<String, dynamic>;
      return CronJob.fromJson(jobData);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskRepository.update DioException — ${e.type}: ${e.message} ===');
      }
      throw _classifyError(e);
    }
  }

  // ─── Delete ───

  /// Delete a cron job by ID.
  Future<void> delete(String id) async {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: TaskRepository.delete — id=$id ===');
    }
    try {
      await _apiClient.delete(ApiEndpoints.jobById(id));
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskRepository.delete DioException — ${e.type}: ${e.message} ===');
      }
      throw _classifyError(e);
    }
  }

  // ─── Actions ───

  /// Trigger an immediate run of a cron job.
  Future<CronJob> runNow(String id) async {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: TaskRepository.runNow — id=$id ===');
    }
    try {
      final response =
          await _apiClient.post('${ApiEndpoints.jobById(id)}/run');
      // DEC-EPIC001-DEPCHECK: POST /run returns {"job": {...}}.
      final jobData = response['job'] as Map<String, dynamic>;
      return CronJob.fromJson(jobData);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskRepository.runNow DioException — ${e.type}: ${e.message} ===');
      }
      throw _classifyError(e);
    }
  }

  /// Pause a cron job.
  Future<CronJob> pause(String id) async {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: TaskRepository.pause — id=$id ===');
    }
    return update(id: id, paused: true);
  }

  /// Resume a paused cron job.
  Future<CronJob> resume(String id) async {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: TaskRepository.resume — id=$id ===');
    }
    return update(id: id, paused: false);
  }

  // ─── Error Classification ───

  static ApiException _classifyError(DioException error) {
    final message = error.message ?? 'Unknown error';
    final statusCode = error.response?.statusCode;
    final body = error.response?.data?.toString();

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ConnectionException(message,
            statusCode: statusCode, responseBody: body);

      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          return AuthException(message,
              statusCode: statusCode, responseBody: body);
        }
        if (statusCode != null && statusCode >= 500) {
          return ServerException(message,
              statusCode: statusCode, responseBody: body);
        }
        return ClientException(message,
            statusCode: statusCode, responseBody: body);

      default:
        return ConnectionException(message,
            statusCode: statusCode, responseBody: body);
    }
  }
}
