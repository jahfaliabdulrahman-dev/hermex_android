import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hermex_android/core/constants/app_strings.dart';
import 'package:hermex_android/core/constants/route_paths.dart';
import 'package:hermex_android/features/connection/presentation/connection_screen.dart';
import 'package:hermex_android/features/connection/data/server_repository.dart';
import 'package:hermex_android/features/connection/providers/connection_provider.dart';
import 'package:hermex_android/models/server_config.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// True if [location] is inside the ShellRoute (matches production _isShellRoutePath).
bool _isShellRoutePath(String location) {
  const shellExact = {'/chat', '/workspace', '/settings'};
  if (shellExact.contains(location)) return true;
  if (location.startsWith('/sessions')) return true;
  if (location.startsWith('/tasks')) return true;
  return false;
}

/// Placeholder screen for GoRouter destinations.
class _LabelScreen extends StatelessWidget {
  final String label;
  const _LabelScreen(this.label);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Text(label)),
      );
}

// ─── Integration Test Notifier ────────────────────────────────────────────────

/// Notifier that simulates connect/disconnect/reconnect without real network calls.
///
/// Tracks an internal servers list so reconnects and server persistence
/// can be verified. Every [simulateConnect] call creates or updates a
/// [ServerConfig] in the list; [simulateDisconnect] clears the active
/// server and resets to idle while preserving the servers list.
class _IntegrationNotifier extends ConnectionNotifier {
  ServerConnectionState _state;
  int _nextServerId = 1;

  /// Create an idle notifier (default).
  _IntegrationNotifier() : _state = const ServerConnectionState();

  /// Create a notifier pre-loaded with [initialState].
  /// Useful when the test needs to start in a connected state without
  /// going through the full connect() flow that requires Riverpod setup.
  _IntegrationNotifier.preloaded(this._state);

  @override
  ServerConnectionState build() => _state;

  /// Override connect() to avoid real health checks.
  @override
  Future<bool> connect({
    required String url,
    required String apiKey,
    String? label,
  }) async {
    // Duplicate submission guard — use _state directly to avoid
    // Riverpod element dependency before widget is mounted.
    if (_state.status == ConnectionStatus.connecting || _state.isBusy) {
      return false;
    }

    // Transition to connecting briefly (simulates network round-trip).
    _emit(_state.copyWith(
      status: ConnectionStatus.connecting,
      errorMessage: null,
      clearError: true,
      isBusy: true,
    ));

    final normalizedUrl =
        url.trim().endsWith('/') ? url.trim().substring(0, url.trim().length - 1) : url.trim();

    final serverName =
        (label != null && label.trim().isNotEmpty) ? label.trim() : normalizedUrl;

    final isLocal = ServerRepository.isLocalNetwork(url);

    // Check whether this server already exists in the saved list.
    final existingIndex =
        _state.servers.indexWhere((s) => s.url == normalizedUrl);
    ServerConfig config;
    List<ServerConfig> updatedServers = List.from(_state.servers);

    if (existingIndex >= 0) {
      config = _state.servers[existingIndex].copyWith(
        name: serverName,
        lastConnected: DateTime.now(),
      );
      updatedServers[existingIndex] = config;
    } else {
      config = ServerConfig(
        id: 's${_nextServerId++}',
        name: serverName,
        url: normalizedUrl,
        isDefault: _state.servers.isEmpty,
        createdAt: DateTime.now(),
        lastConnected: DateTime.now(),
      );
      updatedServers.add(config);
    }

    _emit(ServerConnectionState(
      status: ConnectionStatus.connected,
      activeServer: config,
      servers: updatedServers,
      isLocalNetwork: isLocal,
      isBusy: false,
    ));

    return true;
  }

  /// Disconnect — preserve servers but clear active.
  void simulateDisconnect() {
    _emit(_state.copyWith(
      status: ConnectionStatus.idle,
      activeServer: null,
      clearActiveServer: true,
      errorMessage: null,
      clearError: true,
      isLocalNetwork: false,
      isBusy: false,
    ));
  }

  /// Direct state update with listener notification.
  void _emit(ServerConnectionState newState) {
    _state = newState;
    state = newState;
  }

  /// Expose saved servers for assertions.
  List<ServerConfig> get savedServers => _state.servers;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ===========================================================================
  // BUG-002-P4: Integration — connect → disconnect → reconnect
  // ===========================================================================
  group('BUG-002-P4: connect → disconnect → reconnect integration', () {
    late _IntegrationNotifier notifier;
    late GoRouter router;

    /// Builds a GoRouter wired to the integration notifier with a redirect guard
    /// that mirrors production app_router.dart behavior.
    // ignore: no_leading_underscores_for_local_identifiers
    GoRouter _buildRouter(_IntegrationNotifier notifier) {
      return GoRouter(
        initialLocation: RoutePaths.connection,
        redirect: (context, state) {
          final container = ProviderScope.containerOf(context);
          final conn = container.read(connectionProvider);
          final location = state.uri.toString();

          if (conn.status == ConnectionStatus.idle &&
              location != RoutePaths.connection &&
              _isShellRoutePath(location)) {
            return RoutePaths.connection;
          }
          return null;
        },
        routes: [
          GoRoute(
            path: RoutePaths.connection,
            builder: (context, state) => const ConnectionScreen(),
          ),
          GoRoute(
            path: RoutePaths.chat,
            builder: (context, state) => const _LabelScreen('Chat'),
          ),
        ],
      );
    }

    /// Wraps [router] in a ProviderScope that overrides connectionProvider
    /// with [notifier].
    // ignore: no_leading_underscores_for_local_identifiers
    Widget _testApp(_IntegrationNotifier notifier, GoRouter router) {
      return ProviderScope(
        overrides: [
          connectionProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    setUp(() {
      notifier = _IntegrationNotifier();
      router = _buildRouter(notifier);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Full connect → disconnect → reconnect round-trip
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets(
      'connect → disconnect → reconnect round-trip with server persistence',
      (tester) async {
        // ── Phase A: Start at /connection (idle state) ──────────────────────
        await tester.pumpWidget(_testApp(notifier, router));
        await tester.pumpAndSettle();

        // Verify we're on the connection screen.
        expect(find.byType(ConnectionScreen), findsOneWidget);
        expect(find.text('Chat'), findsNothing);

        // Verify idle state: Connect button visible, no spinner.
        expect(find.text('Connect'), findsOneWidget);
        expect(find.text('Connecting…'), findsNothing);
        expect(find.byType(TextFormField), findsNWidgets(3));

        // ── Phase B: Connect to first server ────────────────────────────────
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'http://192.168.1.100:8642');
        await tester.enterText(fields.at(1), 'sk-test-api-key-1');
        await tester.enterText(fields.last, 'Home Server');
        await tester.pumpAndSettle();

        // Ensure Connect button is visible before tapping.
        await tester.ensureVisible(find.text('Connect'));
        await tester.pumpAndSettle();

        // Tap Connect.
        await tester.tap(find.text('Connect'));
        await tester.pumpAndSettle();

        // A confirmation dialog appears for first-time connections.
        // Tap "Confirm Connect" to proceed.
        expect(find.text(AppStrings.confirmServerTitle), findsOneWidget);
        await tester.tap(find.text(AppStrings.confirmConnect));
        await tester.pumpAndSettle();

        // After successful connect, should navigate to /chat.
        expect(find.text('Chat'), findsOneWidget);
        expect(find.byType(ConnectionScreen), findsNothing);

        // Verify the saved server is in the list.
        expect(notifier.savedServers.length, 1);
        expect(notifier.savedServers.first.url, 'http://192.168.1.100:8642');
        expect(notifier.savedServers.first.name, 'Home Server');

        // ── Phase C: Disconnect ─────────────────────────────────────────────
        notifier.simulateDisconnect();
        await tester.pump();

        // Navigate to any ShellRoute path — the redirect guard should fire
        // because status is now idle.
        router.go(RoutePaths.chat);
        await tester.pumpAndSettle();

        // Should be redirected back to /connection.
        expect(find.byType(ConnectionScreen), findsOneWidget);
        expect(find.text('Chat'), findsNothing);

        // ── Phase D: Verify ConnectionScreen shows idle state ───────────────
        //    (BUG-002: no error banner, no stale local hint, fields enabled)
        expect(find.text('Connect'), findsOneWidget);
        expect(find.text('Connecting…'), findsNothing);

        // No error state.
        expect(find.byIcon(Icons.error_outline), findsNothing);

        // No "Local network detected" hint — isLocalNetwork should be false.
        expect(
          find.text('Local network detected. HTTP is allowed on local networks.'),
          findsNothing,
        );
        expect(find.byIcon(Icons.wifi), findsNothing);

        // Fields should be present and enabled.
        final reentryFields = find.byType(TextFormField);
        expect(reentryFields, findsNWidgets(3));

        // ── Phase E: Connect to a DIFFERENT server ──────────────────────────
        await tester.enterText(reentryFields.first, 'http://10.0.0.50:8642');
        await tester.enterText(reentryFields.at(1), 'sk-test-api-key-2');
        await tester.enterText(reentryFields.last, 'Office Server');
        await tester.pumpAndSettle();

        // Ensure Connect button is visible.
        await tester.ensureVisible(find.text('Connect'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Connect'));
        await tester.pumpAndSettle();

        // Confirmation dialog for the new (different) server.
        expect(find.text(AppStrings.confirmServerTitle), findsOneWidget);
        await tester.tap(find.text(AppStrings.confirmConnect));
        await tester.pumpAndSettle();

        // Should navigate to /chat again.
        expect(find.text('Chat'), findsOneWidget);

        // ── Phase F: Verify first server still exists in saved list ─────────
        expect(notifier.savedServers.length, 2,
            reason: 'Both servers should be saved');

        final urls = notifier.savedServers.map((s) => s.url).toSet();
        expect(urls, contains('http://192.168.1.100:8642'),
            reason: 'First server (Home) should still be in saved list');
        expect(urls, contains('http://10.0.0.50:8642'),
            reason: 'Second server (Office) should be in saved list');

        // Active server should be the second one.
        expect(notifier.build().activeServer?.url, 'http://10.0.0.50:8642');

        // ── Phase G: Reconnect to first server (reconnect flow) ─────────────
        notifier.simulateDisconnect();
        await tester.pump();

        router.go(RoutePaths.chat);
        await tester.pumpAndSettle();

        // Back at /connection.
        expect(find.byType(ConnectionScreen), findsOneWidget);

        // Re-enter the first server URL.
        final reconnectFields = find.byType(TextFormField);
        await tester.enterText(reconnectFields.first, 'http://192.168.1.100:8642');
        await tester.enterText(reconnectFields.at(1), 'sk-test-api-key-1');
        await tester.enterText(reconnectFields.last, 'Home Server');
        await tester.pumpAndSettle();

        // Ensure Connect button is visible.
        await tester.ensureVisible(find.text('Connect'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Connect'));
        await tester.pumpAndSettle();

        // The first server already exists — no confirmation dialog expected.
        // (isNewServer should be false since it's already in the list.)
        // Verify we go directly to /chat (no dialog appeared).
        expect(find.text('Chat'), findsOneWidget);
        expect(find.byType(ConnectionScreen), findsNothing);

        // Verify servers list still has exactly 2 (no duplicates).
        expect(notifier.savedServers.length, 2,
            reason: 'Reconnect to existing server should not create duplicate');
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Double-tap on Connect does not trigger duplicate navigation
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets(
      'duplicate tap on Connect is blocked (idempotency)',
      (tester) async {
        await tester.pumpWidget(_testApp(notifier, router));
        await tester.pumpAndSettle();

        // Enter valid URL and API key.
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'http://192.168.1.100:8642');
        await tester.enterText(fields.at(1), 'sk-test-api-key');
        await tester.pumpAndSettle();

        // Ensure Connect button is visible before tapping (keyboard may push it off-screen).
        await tester.ensureVisible(find.text('Connect'));
        await tester.pumpAndSettle();

        // Tap Connect twice rapidly.
        await tester.tap(find.text('Connect'));
        await tester.tap(find.text('Connect'));
        await tester.pump();

        // Confirmation dialog should appear (first tap triggered it).
        // The second tap was blocked by the connecting state.
        expect(find.text(AppStrings.confirmServerTitle), findsOneWidget);

        // Tap confirm.
        await tester.tap(find.text(AppStrings.confirmConnect));
        await tester.pumpAndSettle();

        // Should end up at /chat exactly once (no double navigation stack).
        expect(find.text('Chat'), findsOneWidget);
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Tailscale IP acceptance (BUG-001 cross-validation)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets(
      'Tailscale 100.64.x.x IP is accepted for connection',
      (tester) async {
        await tester.pumpWidget(_testApp(notifier, router));
        await tester.pumpAndSettle();

        final fields = find.byType(TextFormField);
        // Tailscale CGNAT range IP.
        await tester.enterText(fields.first, 'http://100.64.0.1:8642');
        await tester.enterText(fields.at(1), 'sk-tailscale-key');
        await tester.pumpAndSettle();

        // Ensure Connect button is visible.
        await tester.ensureVisible(find.text('Connect'));
        await tester.pumpAndSettle();

        // Tap Connect — should validate without error (BUG-001).
        await tester.tap(find.text('Connect'));
        await tester.pumpAndSettle();

        // Confirmation dialog appears — means validation passed.
        expect(find.text(AppStrings.confirmServerTitle), findsOneWidget);

        await tester.tap(find.text(AppStrings.confirmConnect));
        await tester.pumpAndSettle();

        // Should navigate to /chat.
        expect(find.text('Chat'), findsOneWidget);

        // Server should be saved.
        expect(notifier.savedServers.length, 1);
        expect(notifier.savedServers.first.url, 'http://100.64.0.1:8642');
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Disconnect → redirect guard blocks ShellRoute access
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets(
      'disconnect from /chat redirects to /connection via guard',
      (tester) async {
        // Create a preloaded notifier that starts CONNECTED.
        final connectedState = ServerConnectionState(
          status: ConnectionStatus.connected,
          activeServer: ServerConfig(
            id: 'preloaded-1',
            name: 'Preloaded',
            url: 'http://192.168.1.100:8642',
            createdAt: DateTime(2026),
          ),
          servers: [
            ServerConfig(
              id: 'preloaded-1',
              name: 'Preloaded',
              url: 'http://192.168.1.100:8642',
              createdAt: DateTime(2026),
            ),
          ],
          isLocalNetwork: true,
        );
        final preloadedNotifier = _IntegrationNotifier.preloaded(connectedState);
        final localRouter = _buildRouter(preloadedNotifier);

        await tester.pumpWidget(_testApp(preloadedNotifier, localRouter));
        await tester.pumpAndSettle();

        // Go to /chat — should succeed since we're connected.
        localRouter.go(RoutePaths.chat);
        await tester.pumpAndSettle();
        expect(find.text('Chat'), findsOneWidget);

        // Disconnect.
        preloadedNotifier.simulateDisconnect();
        await tester.pump();

        // Try navigating to /chat — guard should redirect.
        localRouter.go(RoutePaths.chat);
        await tester.pumpAndSettle();

        // Back at /connection.
        expect(find.byType(ConnectionScreen), findsOneWidget);
        expect(find.text('Chat'), findsNothing);
      },
    );
  });
}
