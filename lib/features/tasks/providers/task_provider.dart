import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_manager.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../models/cron_job.dart';
import '../../connection/providers/connection_provider.dart';
import '../data/task_repository.dart';

// ─── State ───

/// Status of a task list or detail load operation.
enum TaskLoadStatus {
  /// Initial state, no load attempted yet.
  idle,

  /// Loading jobs from the server.
  loading,

  /// Jobs loaded successfully.
  success,

  /// Load failed. [errorMessage] contains details.
  error,
}

/// UI state for the task list screen.
class TaskListState {
  /// Current load status.
  final TaskLoadStatus status;

  /// All cron jobs from the server.
  final List<CronJob> jobs;

  /// Error message when status is [TaskLoadStatus.error].
  final String? errorMessage;

  /// Whether a mutation (create/update/delete/action) is in progress.
  final bool isBusy;

  /// ID of the job currently being mutated (for per-row loading indicators).
  final String? busyJobId;

  /// Whether the current user action is a "Run Now" trigger.
  final bool isRunNow;

  /// Whether a delete operation is in progress.
  final bool isDeleting;

  const TaskListState({
    this.status = TaskLoadStatus.idle,
    this.jobs = const [],
    this.errorMessage,
    this.isBusy = false,
    this.busyJobId,
    this.isRunNow = false,
    this.isDeleting = false,
  });

  TaskListState copyWith({
    TaskLoadStatus? status,
    List<CronJob>? jobs,
    String? errorMessage,
    bool clearError = false,
    bool? isBusy,
    String? busyJobId,
    bool clearBusyJobId = false,
    bool? isRunNow,
    bool? isDeleting,
  }) =>
      TaskListState(
        status: status ?? this.status,
        jobs: jobs ?? this.jobs,
        errorMessage:
            clearError ? null : (errorMessage ?? this.errorMessage),
        isBusy: isBusy ?? this.isBusy,
        busyJobId: clearBusyJobId ? null : (busyJobId ?? this.busyJobId),
        isRunNow: isRunNow ?? this.isRunNow,
        isDeleting: isDeleting ?? this.isDeleting,
      );
}

// ─── Notifier ───

/// Notifier for task list management.
///
/// Manages: load, create, update, delete, runNow, pause, resume.
/// Uses [TaskRepository] for server communication.
///
/// NOT autoDispose — this is a shared, long-lived controller (DEC-034 rule 2).
class TaskListNotifier extends Notifier<TaskListState> {
  TaskRepository? _repository;

  /// Guards against concurrent _loadJobs() calls.
  /// Separate from [TaskListState.isBusy] which is for per-row UI indicators.
  bool _isLoadingJobs = false;

  @override
  TaskListState build() {
    // Auto-load jobs when the widget tree is ready.
    _initRepositoryAndLoad();
    return const TaskListState();
  }

  /// Initialize the repository from the active server connection.
  /// If no active server, the repository stays null — operations will fail gracefully.
  Future<void> _initRepositoryAndLoad() async {
    final connectionState = ref.read(connectionProvider);
    final activeServer = connectionState.activeServer;
    if (activeServer == null) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier — no active server, skipping load ===');
      }
      return;
    }

    final authManager = AuthManager(secureStorage: SecureStorage());
    final apiKey = await authManager.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier — no API key, skipping load ===');
      }
      return;
    }

    _repository = TaskRepository(
      apiClient: ApiClient(baseUrl: activeServer.url, apiKey: apiKey),
    );

    // Load jobs after repository is initialized.
    await _loadJobs();
  }

  /// Create a new repository for the current active server, or return null.
  Future<TaskRepository?> _getRepository() async {
    if (_repository != null) return _repository;

    final connectionState = ref.read(connectionProvider);
    final activeServer = connectionState.activeServer;
    if (activeServer == null) return null;

    final authManager = AuthManager(secureStorage: SecureStorage());
    final apiKey = await authManager.getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    _repository = TaskRepository(
      apiClient: ApiClient(baseUrl: activeServer.url, apiKey: apiKey),
    );
    return _repository;
  }

  /// Load jobs from the server.
  Future<void> _loadJobs() async {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: TaskListNotifier._loadJobs ===');
    }

    // Prevent duplicate loads.
    // Uses private _isLoadingJobs flag — state.isBusy is for per-row UI indicators
    // and must not block internal refresh calls from mutation methods.
    if (state.status == TaskLoadStatus.loading || _isLoadingJobs) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier._loadJobs — blocked: already loading ===');
      }
      return;
    }

    final repo = await _getRepository();
    if (repo == null) {
      state = state.copyWith(
        status: TaskLoadStatus.error,
        errorMessage: 'Not connected to a server. Please connect first.',
      );
      return;
    }

    _isLoadingJobs = true;
    state = state.copyWith(
      status: TaskLoadStatus.loading,
      errorMessage: null,
      clearError: true,
    );

    try {
      final jobs = await repo.getAll();
      _isLoadingJobs = false;
      state = state.copyWith(
        status: TaskLoadStatus.success,
        jobs: jobs,
      );
    } catch (e) {
      _isLoadingJobs = false;
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier._loadJobs — error: $e ===');
      }
      state = state.copyWith(
        status: TaskLoadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Public method to refresh (pull-to-refresh).
  Future<void> refreshJobs() async {
    await _loadJobs();
  }

  // ─── Create ───

  /// Create a new cron job. Returns true on success.
  Future<bool> createJob({
    required String prompt,
    required String schedule,
    String? name,
    List<String>? skills,
    String? modelProvider,
    String? modelName,
    String? deliver,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: TaskListNotifier.createJob — schedule=$schedule ===');
    }

    if (state.isBusy) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier.createJob — blocked: already busy ===');
      }
      return false;
    }

    final repo = await _getRepository();
    if (repo == null) {
      state = state.copyWith(
        errorMessage: 'Not connected to a server.',
      );
      return false;
    }

    state = state.copyWith(isBusy: true, errorMessage: null, clearError: true);

    try {
      await repo.create(
        prompt: prompt,
        schedule: schedule,
        name: name,
        skills: skills,
        modelProvider: modelProvider,
        modelName: modelName,
        deliver: deliver,
      );
      await _loadJobs();
      state = state.copyWith(isBusy: false);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier.createJob — error: $e ===');
      }
      state = state.copyWith(
        isBusy: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // ─── Update ───

  /// Update an existing cron job. Returns true on success.
  Future<bool> updateJob({
    required String id,
    String? prompt,
    String? schedule,
    String? name,
    List<String>? skills,
    String? modelProvider,
    String? modelName,
    String? deliver,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: TaskListNotifier.updateJob — id=$id ===');
    }

    if (state.isBusy) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier.updateJob — blocked: already busy ===');
      }
      return false;
    }

    final repo = await _getRepository();
    if (repo == null) {
      state = state.copyWith(errorMessage: 'Not connected to a server.');
      return false;
    }

    state = state.copyWith(
      isBusy: true,
      busyJobId: id,
      errorMessage: null,
      clearError: true,
    );

    try {
      await repo.update(
        id: id,
        prompt: prompt,
        schedule: schedule,
        name: name,
        skills: skills,
        modelProvider: modelProvider,
        modelName: modelName,
        deliver: deliver,
      );
      await _loadJobs();
      state = state.copyWith(isBusy: false, clearBusyJobId: true);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier.updateJob — error: $e ===');
      }
      state = state.copyWith(
        isBusy: false,
        clearBusyJobId: true,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // ─── Delete ───

  /// Delete a cron job. Returns true on success.
  Future<bool> deleteJob(String id) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: TaskListNotifier.deleteJob — id=$id ===');
    }

    if (state.isBusy) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier.deleteJob — blocked: already busy ===');
      }
      return false;
    }

    final repo = await _getRepository();
    if (repo == null) {
      state = state.copyWith(errorMessage: 'Not connected to a server.');
      return false;
    }

    state = state.copyWith(
      isBusy: true,
      busyJobId: id,
      isDeleting: true,
      errorMessage: null,
      clearError: true,
    );

    try {
      await repo.delete(id);
      await _loadJobs();
      state = state.copyWith(
        isBusy: false,
        clearBusyJobId: true,
        isDeleting: false,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier.deleteJob — error: $e ===');
      }
      state = state.copyWith(
        isBusy: false,
        clearBusyJobId: true,
        isDeleting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // ─── Run Now ───

  /// Trigger an immediate run of a cron job. Returns true on success.
  Future<bool> runJobNow(String id) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: TaskListNotifier.runJobNow — id=$id ===');
    }

    if (state.isBusy) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier.runJobNow — blocked: already busy ===');
      }
      return false;
    }

    final repo = await _getRepository();
    if (repo == null) {
      state = state.copyWith(errorMessage: 'Not connected to a server.');
      return false;
    }

    state = state.copyWith(
      isBusy: true,
      busyJobId: id,
      isRunNow: true,
      errorMessage: null,
      clearError: true,
    );

    try {
      await repo.runNow(id);
      await _loadJobs();
      state = state.copyWith(
        isBusy: false,
        clearBusyJobId: true,
        isRunNow: false,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier.runJobNow — error: $e ===');
      }
      state = state.copyWith(
        isBusy: false,
        clearBusyJobId: true,
        isRunNow: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // ─── Pause / Resume ───

  /// Pause a cron job. Returns true on success.
  Future<bool> pauseJob(String id) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: TaskListNotifier.pauseJob — id=$id ===');
    }

    if (state.isBusy) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier.pauseJob — blocked: already busy ===');
      }
      return false;
    }

    final repo = await _getRepository();
    if (repo == null) {
      state = state.copyWith(errorMessage: 'Not connected to a server.');
      return false;
    }

    state = state.copyWith(
      isBusy: true,
      busyJobId: id,
      errorMessage: null,
      clearError: true,
    );

    try {
      await repo.pause(id);
      await _loadJobs();
      state = state.copyWith(isBusy: false, clearBusyJobId: true);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier.pauseJob — error: $e ===');
      }
      state = state.copyWith(
        isBusy: false,
        clearBusyJobId: true,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Resume a paused cron job. Returns true on success.
  Future<bool> resumeJob(String id) async {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: TaskListNotifier.resumeJob — id=$id ===');
    }

    if (state.isBusy) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier.resumeJob — blocked: already busy ===');
      }
      return false;
    }

    final repo = await _getRepository();
    if (repo == null) {
      state = state.copyWith(errorMessage: 'Not connected to a server.');
      return false;
    }

    state = state.copyWith(
      isBusy: true,
      busyJobId: id,
      errorMessage: null,
      clearError: true,
    );

    try {
      await repo.resume(id);
      await _loadJobs();
      state = state.copyWith(isBusy: false, clearBusyJobId: true);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '=== HERMEX DEBUG: TaskListNotifier.resumeJob — error: $e ===');
      }
      state = state.copyWith(
        isBusy: false,
        clearBusyJobId: true,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Clear the current error state.
  void clearError() {
    state = state.copyWith(
      status: TaskLoadStatus.idle,
      errorMessage: null,
      clearError: true,
    );
  }
}

// ─── Providers ───

/// Provider for the task list notifier.
/// NOT autoDispose — this is a shared, long-lived controller (DEC-034 rule 2).
final taskListProvider =
    NotifierProvider<TaskListNotifier, TaskListState>(
  TaskListNotifier.new,
);

/// Provider for a single job detail (fetched on demand).
final taskDetailProvider =
    FutureProvider.family<CronJob?, String>((ref, id) async {
  if (kDebugMode) {
    debugPrint('=== HERMEX DEBUG: taskDetailProvider — id=$id ===');
  }

  final connectionState = ref.read(connectionProvider);
  final activeServer = connectionState.activeServer;
  if (activeServer == null) {
    throw StateError('No active server — connect to a server first.');
  }

  final authManager = AuthManager(secureStorage: SecureStorage());
  final apiKey = await authManager.getApiKey();
  if (apiKey == null || apiKey.isEmpty) {
    throw StateError('No API key — please reconnect.');
  }

  final apiClient = ApiClient(baseUrl: activeServer.url, apiKey: apiKey);
  final repository = TaskRepository(apiClient: apiClient);
  return repository.getById(id);
});
