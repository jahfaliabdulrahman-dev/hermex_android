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

/// Centralized provider that resolves a fully-configured ApiClient.
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
