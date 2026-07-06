import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/endpoints.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../models/memory_entry.dart';

/// Riverpod provider for the agent memory list.
///
/// Fetches from GET /v1/memory. Returns empty list when:
/// - No server connected (resolvedApiClientProvider returns null)
/// - Server returns empty response
/// - API call fails (logs error, returns empty)
///
/// Handles: Loading, Success (list), Empty, Error
final memoryListProvider = FutureProvider<List<MemoryEntry>>((ref) async {
  final apiClientAsync = ref.watch(resolvedApiClientProvider);
  final apiClient = apiClientAsync.valueOrNull;
  if (apiClient == null) {
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: memoryListProvider — no active server, returning empty ===');
    }
    return [];
  }

  if (kDebugMode) {
    debugPrint('=== HERMEX DEBUG: memoryListProvider — fetching ===');
  }
  try {
    final response = await apiClient.get(ApiEndpoints.memory);
    final entries = MemoryEntry.parseList(response);
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: memoryListProvider — got ${entries.length} entries ===');
    }
    return entries;
  } catch (e, stack) {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: memoryListProvider — error: $e ===');
    }
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: memoryListProvider — stack: $stack ===');
    }
    throw Exception('Failed to load memory entries: $e');
  }
});
