/// Insights / usage statistics returned by the Hermes Agent API (GET /v1/insights).
///
/// This is a read-only API model — not persisted locally.
class InsightsData {
  /// Total number of sessions.
  final int totalSessions;

  /// Total number of messages across all sessions.
  final int totalMessages;

  /// Total tokens consumed (input + output).
  final int totalTokens;

  /// Approximate active time in minutes.
  final int activeTimeMinutes;

  /// Last sync timestamp from the server.
  final DateTime? lastSynced;

  /// Number of cron jobs executed.
  final int cronJobsRun;

  /// Number of skills installed.
  final int skillsCount;

  const InsightsData({
    this.totalSessions = 0,
    this.totalMessages = 0,
    this.totalTokens = 0,
    this.activeTimeMinutes = 0,
    this.lastSynced,
    this.cronJobsRun = 0,
    this.skillsCount = 0,
  });

  // ─── Convenience ───

  /// Active time formatted as "Xh Ym" or "Ym".
  String get formattedActiveTime {
    if (activeTimeMinutes < 1) return '0m';
    final hours = activeTimeMinutes ~/ 60;
    final minutes = activeTimeMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  /// Token count formatted with k/m suffix for readability.
  String get formattedTokens {
    if (totalTokens >= 1000000) {
      return '${(totalTokens / 1000000).toStringAsFixed(1)}M';
    }
    if (totalTokens >= 1000) {
      return '${(totalTokens / 1000).toStringAsFixed(1)}k';
    }
    return totalTokens.toString();
  }

  // ─── JSON Parsing (safe — handles malformed payloads) ───

  factory InsightsData.fromJson(Map<String, dynamic> json) {
    return InsightsData(
      totalSessions: _parseInt(json['total_sessions'] ?? json['totalSessions']),
      totalMessages: _parseInt(json['total_messages'] ?? json['totalMessages']),
      totalTokens: _parseInt(json['total_tokens'] ?? json['totalTokens']),
      activeTimeMinutes:
          _parseInt(json['active_time_minutes'] ?? json['activeTimeMinutes']),
      lastSynced: json['last_synced'] != null
          ? DateTime.tryParse(json['last_synced'].toString())
          : null,
      cronJobsRun:
          _parseInt(json['cron_jobs_run'] ?? json['cronJobsRun']),
      skillsCount: _parseInt(json['skills_count'] ?? json['skillsCount']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  /// Parse from API response body.
  /// The API may return the data directly or wrapped in an object.
  static InsightsData parse(dynamic body) {
    if (body == null) return const InsightsData();
    if (body is Map<String, dynamic>) {
      // Check for nested 'insights' or 'data' key.
      final data = body['insights'] ?? body['data'] ?? body;
      if (data is Map<String, dynamic>) {
        return InsightsData.fromJson(data);
      }
    }
    return const InsightsData();
  }

  // ─── Equality ───

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightsData &&
          runtimeType == other.runtimeType &&
          totalSessions == other.totalSessions &&
          totalMessages == other.totalMessages &&
          totalTokens == other.totalTokens &&
          activeTimeMinutes == other.activeTimeMinutes;

  @override
  int get hashCode => Object.hash(
        totalSessions,
        totalMessages,
        totalTokens,
        activeTimeMinutes,
      );

  @override
  String toString() =>
      'InsightsData(sessions: $totalSessions, messages: $totalMessages, '
      'tokens: $totalTokens, active: $formattedActiveTime)';
}
