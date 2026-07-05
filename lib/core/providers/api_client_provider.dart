import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/auth_manager.dart';
import '../security/certificate_pinner.dart';
import '../storage/secure_storage.dart';
import '../../features/connection/providers/connection_provider.dart';

/// AUD-001: Singleton CertificatePinner — initialized once at app startup.
/// Loads pinned cert fingerprints from SharedPreferences and provides
/// synchronous validation for Dio's HttpClient.badCertificateCallback.
final certificatePinnerProvider = FutureProvider<CertificatePinner>((ref) async {
  final pinner = CertificatePinner();
  await pinner.init();
  if (kDebugMode) {
    debugPrint('=== HERMEX DEBUG: certificatePinnerProvider — initialized ===');
  }
  return pinner;
});

/// Centralized ApiClient provider — depends on the active server connection.
///
/// Reads the active server URL from [connectionProvider] and the API key
/// from [AuthManager] backed by secure storage.
///
/// Returns null when no active server is configured — features should
/// guard against null or redirect to the connection screen.
final apiClientProvider = Provider<ApiClient?>((ref) {
  final connectionState = ref.watch(connectionProvider);
  final activeServer = connectionState.activeServer;
  if (activeServer == null) return null;

  // Asynchronous API key resolution is handled by resolvedApiClientProvider below.
  return null; // Placeholder — resolved async below.
});

/// Async provider that resolves the ApiClient once the API key is available.
///
/// Features should use this provider. It:
/// - Watches the active server config from [connectionProvider]
/// - Reads the API key from secure storage asynchronously
/// - Initializes the CertificatePinner (AUD-001)
/// - Returns a fully-configured [ApiClient] or null
final resolvedApiClientProvider = FutureProvider<ApiClient?>((ref) async {
  final connectionState = ref.watch(connectionProvider);
  final activeServer = connectionState.activeServer;
  if (activeServer == null) {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: resolvedApiClientProvider — no active server ===');
    }
    return null;
  }

  final authManager = AuthManager(secureStorage: SecureStorage());
  final apiKey = await authManager.getApiKey();
  if (apiKey == null || apiKey.isEmpty) {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: resolvedApiClientProvider — no API key for server ${activeServer.id} ===');
    }
    return null;
  }

  // AUD-001: Initialize certificate pinner for TOFU-based MITM protection.
  final pinner = await ref.watch(certificatePinnerProvider.future);

  if (kDebugMode) {
    debugPrint('=== HERMEX DEBUG: resolvedApiClientProvider — creating client for ${activeServer.url} ===');
  }
  // NOTE: activeServer.url is logged for debugging; apiKey is NEVER logged.
  return ApiClient(
    baseUrl: activeServer.url,
    apiKey: apiKey,
    certificatePinner: pinner,
  );
});
