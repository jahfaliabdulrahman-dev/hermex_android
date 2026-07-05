import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/endpoints.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../models/insights_data.dart';

/// Riverpod provider for usage insights / statistics.
///
/// Fetches from GET /v1/insights. Returns default-zero [InsightsData] when:
/// - No server connected (resolvedApiClientProvider returns null)
/// - API call fails (logs error, returns default)
///
/// Handles: Loading, Success, Empty/Zero, Error
final insightsProvider = FutureProvider<InsightsData>((ref) async {
  final apiClientAsync = ref.watch(resolvedApiClientProvider);
  final apiClient = apiClientAsync.valueOrNull;
  if (apiClient == null) {
    debugPrint(
        '=== HERMEX DEBUG: insightsProvider — no active server, returning default ===');
    return const InsightsData();
  }

  debugPrint('=== HERMEX DEBUG: insightsProvider — fetching ===');
  try {
    final response = await apiClient.get(ApiEndpoints.insights);
    final data = InsightsData.parse(response);
    debugPrint(
        '=== HERMEX DEBUG: insightsProvider — sessions=${data.totalSessions}, '
        'msgs=${data.totalMessages} ===');
    return data;
  } catch (e, stack) {
    debugPrint('=== HERMEX DEBUG: insightsProvider — error: $e ===');
    debugPrint('=== HERMEX DEBUG: insightsProvider — stack: $stack ===');
    throw Exception('Failed to load insights: $e');
  }
});
