import 'package:intl/intl.dart';

/// Date and time formatting utilities for Hermex Android.
///
/// Supports relative time (e.g., "2h ago", "yesterday")
/// and Arabic locale formatting.
abstract class DateFormatter {
  DateFormatter._();

  /// Format a [DateTime] as a relative time string.
  ///
  /// Examples:
  /// - "just now" (< 1 minute)
  /// - "5m ago"
  /// - "2h ago"
  /// - "yesterday"
  /// - "3d ago"
  /// - "Jul 5" (older than 7 days)
  static String relativeTime(DateTime dateTime, {String locale = 'en'}) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      return DateFormat('MMM d', locale).format(dateTime);
    } else {
      return DateFormat('MMM d, yyyy', locale).format(dateTime);
    }
  }

  /// Format a [DateTime] for full display (e.g., "July 5, 2026").
  static String fullDate(DateTime dateTime, {String locale = 'en'}) {
    return DateFormat.yMMMMd(locale).format(dateTime);
  }

  /// Format a [DateTime] for time-only display (e.g., "14:30").
  static String timeOnly(DateTime dateTime, {String locale = 'en'}) {
    return DateFormat.Hm(locale).format(dateTime);
  }

  /// Format a [DateTime] with date and time (e.g., "Jul 5, 14:30").
  static String dateAndTime(DateTime dateTime, {String locale = 'en'}) {
    final date = DateFormat('MMM d', locale).format(dateTime);
    final time = DateFormat.Hm(locale).format(dateTime);
    return '$date, $time';
  }

  /// Format a cron schedule string into a human-readable description.
  ///
  /// Supports simple interpretations:
  /// - "0 9 * * *" → "daily at 09:00"
  /// - "*/30 * * * *" → "every 30 minutes"
  /// - "0 */2 * * *" → "every 2 hours"
  static String scheduleDescription(String schedule) {
    final parts = schedule.trim().split(RegExp(r'\s+'));
    if (parts.length != 5) return schedule; // not a cron expression

    final minute = parts[0];
    final hour = parts[1];

    // "every X minutes" pattern
    if (minute.startsWith('*/')) {
      final interval = minute.substring(2);
      final mins = int.tryParse(interval) ?? 0;
      if (mins > 0) return 'every $mins minutes';
    }

    // "daily at HH:MM" pattern
    if (hour != '*' && minute != '*') {
      final h = hour.padLeft(2, '0');
      final m = minute.padLeft(2, '0');
      return 'daily at $h:$m';
    }

    // "every X hours" pattern
    if (hour.startsWith('*/')) {
      final interval = hour.substring(2);
      final hrs = int.tryParse(interval) ?? 0;
      if (hrs > 0) return 'every $hrs hours';
    }

    return schedule; // fallback — show raw cron
  }

  /// Format a cron next-run timestamp with relative + absolute.
  static String nextRunLabel(DateTime? nextRun, {String locale = 'en'}) {
    if (nextRun == null) return '—';
    final relative = relativeTime(nextRun, locale: locale);
    return 'Next: $relative';
  }

  /// Format duration since last run as a concise string.
  static String timeSince(DateTime? dateTime, {String locale = 'en'}) {
    if (dateTime == null) return 'never';
    return relativeTime(dateTime, locale: locale);
  }

  /// Check if a cached item is stale (older than [maxAge]).
  static bool isStale(DateTime cachedAt, {Duration maxAge = const Duration(days: 7)}) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}
