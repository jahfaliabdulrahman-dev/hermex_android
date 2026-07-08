import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hermex_android/core/constants/route_paths.dart';
import 'package:hermex_android/features/connection/providers/connection_provider.dart';

/// Widget tests for the GoRouter redirect guard added for BUG-002-P2.
///
/// The redirect guard watches [ConnectionStatus] and redirects any
/// ShellRoute page to /connection when the status is idle.
///
/// ShellRoute pages: /chat, /sessions/*, /tasks/*, /workspace, /settings
/// Non-ShellRoute pages (no redirect): /connection, /servers, /skills,
/// /memory, /insights, /settings/license

/// Helper: returns true if [location] is inside the ShellRoute.
///
/// Mirrors [_isShellRoutePath] in app_router.dart — kept identical for
/// test symmetry so routing behavior matches production exactly.
bool isShellRoutePath(String location) {
  const shellExact = {'/chat', '/workspace', '/settings'};
  if (shellExact.contains(location)) return true;
  if (location.startsWith('/sessions')) return true;
  if (location.startsWith('/tasks')) return true;
  return false;
}

/// Factory for a GoRouter wired with the redirect guard.
///
/// Uses a fixed initial [status] passed to the test provider so each
/// test controls the connection state independently.
GoRouter _testRouter(ConnectionStatus status) {
  return GoRouter(
    initialLocation: RoutePaths.connection,
    redirect: (context, state) {
      final container = ProviderScope.containerOf(context);
      final connState = container.read(connectionProvider);
      final location = state.uri.toString();

      if (connState.status == ConnectionStatus.idle &&
          location != RoutePaths.connection &&
          isShellRoutePath(location)) {
        return RoutePaths.connection;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.connection,
        builder: (_, _) => const _TestScreen('Connection'),
      ),
      GoRoute(
        path: RoutePaths.chat,
        builder: (_, _) => const _TestScreen('Chat'),
      ),
      GoRoute(
        path: RoutePaths.sessions,
        builder: (_, _) => const _TestScreen('Sessions'),
      ),
      GoRoute(
        path: RoutePaths.tasks,
        builder: (_, _) => const _TestScreen('Tasks'),
      ),
      GoRoute(
        path: RoutePaths.workspace,
        builder: (_, _) => const _TestScreen('Workspace'),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (_, _) => const _TestScreen('Settings'),
      ),
      GoRoute(
        path: RoutePaths.servers,
        builder: (_, _) => const _TestScreen('Servers'),
      ),
      GoRoute(
        path: RoutePaths.skills,
        builder: (_, _) => const _TestScreen('Skills'),
      ),
      GoRoute(
        path: RoutePaths.memory,
        builder: (_, _) => const _TestScreen('Memory'),
      ),
      GoRoute(
        path: RoutePaths.insights,
        builder: (_, _) => const _TestScreen('Insights'),
      ),
      GoRoute(
        path: RoutePaths.license,
        builder: (_, _) => const _TestScreen('License'),
      ),
    ],
  );
}

/// Minimal screen widget for testing the redirect.
class _TestScreen extends StatelessWidget {
  final String label;
  const _TestScreen(this.label);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Text(label)),
      );
}

/// Wraps [router] in a ProviderScope with the given connection [status].
Widget _wrap(GoRouter router, ConnectionStatus status) {
  return ProviderScope(
    overrides: [
      connectionProvider.overrideWith(
        () => _FixedConnectionNotifier(status),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Notifier that always returns the given [status] and never changes.
class _FixedConnectionNotifier extends ConnectionNotifier {
  final ConnectionStatus _status;

  _FixedConnectionNotifier(this._status);

  @override
  ServerConnectionState build() => ServerConnectionState(status: _status);
}

void main() {
  group('GoRouter redirect guard — idle state', () {
    for (final path in ['/chat', '/sessions', '/sessions/abc',
         '/tasks', '/tasks/new', '/tasks/abc', '/tasks/abc/edit',
         '/workspace', '/settings']) {
      testWidgets('redirects $path → /connection', (tester) async {
        final router = _testRouter(ConnectionStatus.idle);
        await tester.pumpWidget(_wrap(router, ConnectionStatus.idle));

        router.go(path);
        await tester.pumpAndSettle();

        expect(find.text('Connection'), findsOneWidget);
        expect(find.text('Chat'), findsNothing);
      });
    }

    testWidgets('no redirect when already on /connection', (tester) async {
      final router = _testRouter(ConnectionStatus.idle);
      await tester.pumpWidget(_wrap(router, ConnectionStatus.idle));
      await tester.pumpAndSettle();

      // Already on /connection (initialLocation) — should stay there.
      expect(find.text('Connection'), findsOneWidget);
    });

    testWidgets('no redirect from /servers (non-ShellRoute)',
        (tester) async {
      final router = _testRouter(ConnectionStatus.idle);
      await tester.pumpWidget(_wrap(router, ConnectionStatus.idle));

      router.go(RoutePaths.servers);
      await tester.pumpAndSettle();

      expect(find.text('Servers'), findsOneWidget);
    });

    testWidgets('no redirect from /skills (non-ShellRoute)',
        (tester) async {
      final router = _testRouter(ConnectionStatus.idle);
      await tester.pumpWidget(_wrap(router, ConnectionStatus.idle));

      router.go(RoutePaths.skills);
      await tester.pumpAndSettle();

      expect(find.text('Skills'), findsOneWidget);
    });

    testWidgets('no redirect from /memory (non-ShellRoute)',
        (tester) async {
      final router = _testRouter(ConnectionStatus.idle);
      await tester.pumpWidget(_wrap(router, ConnectionStatus.idle));

      router.go(RoutePaths.memory);
      await tester.pumpAndSettle();

      expect(find.text('Memory'), findsOneWidget);
    });

    testWidgets('no redirect from /insights (non-ShellRoute)',
        (tester) async {
      final router = _testRouter(ConnectionStatus.idle);
      await tester.pumpWidget(_wrap(router, ConnectionStatus.idle));

      router.go(RoutePaths.insights);
      await tester.pumpAndSettle();

      expect(find.text('Insights'), findsOneWidget);
    });

    testWidgets('no redirect from /settings/license (non-ShellRoute)',
        (tester) async {
      final router = _testRouter(ConnectionStatus.idle);
      await tester.pumpWidget(_wrap(router, ConnectionStatus.idle));

      router.go(RoutePaths.license);
      await tester.pumpAndSettle();

      expect(find.text('License'), findsOneWidget);
    });
  });

  group('GoRouter redirect guard — connected state', () {
    testWidgets('no redirect from /chat when connected', (tester) async {
      final router = _testRouter(ConnectionStatus.connected);
      await tester.pumpWidget(_wrap(router, ConnectionStatus.connected));

      router.go(RoutePaths.chat);
      await tester.pumpAndSettle();

      expect(find.text('Chat'), findsOneWidget);
    });

    testWidgets('no redirect from /sessions when connected',
        (tester) async {
      final router = _testRouter(ConnectionStatus.connected);
      await tester.pumpWidget(_wrap(router, ConnectionStatus.connected));

      router.go(RoutePaths.sessions);
      await tester.pumpAndSettle();

      expect(find.text('Sessions'), findsOneWidget);
    });

    testWidgets('no redirect from /tasks when connected', (tester) async {
      final router = _testRouter(ConnectionStatus.connected);
      await tester.pumpWidget(_wrap(router, ConnectionStatus.connected));

      router.go(RoutePaths.tasks);
      await tester.pumpAndSettle();

      expect(find.text('Tasks'), findsOneWidget);
    });

    testWidgets('no redirect from /workspace when connected',
        (tester) async {
      final router = _testRouter(ConnectionStatus.connected);
      await tester.pumpWidget(_wrap(router, ConnectionStatus.connected));

      router.go(RoutePaths.workspace);
      await tester.pumpAndSettle();

      expect(find.text('Workspace'), findsOneWidget);
    });

    testWidgets('no redirect from /settings when connected',
        (tester) async {
      final router = _testRouter(ConnectionStatus.connected);
      await tester.pumpWidget(_wrap(router, ConnectionStatus.connected));

      router.go(RoutePaths.settings);
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
