import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_paths.dart';
import '../../features/connection/providers/connection_provider.dart';
import '../../features/connection/presentation/connection_screen.dart';
import '../../features/connection/presentation/server_list_screen.dart';
import '../../features/sessions/presentation/session_list_screen.dart';
import '../../features/sessions/presentation/session_detail_screen.dart';
import '../../features/tasks/presentation/task_list_screen.dart';
import '../../features/tasks/presentation/task_detail_screen.dart';
import '../../features/tasks/presentation/task_form_screen.dart';
import '../../features/memory/presentation/memory_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/workspace/presentation/workspace_screen.dart';
import '../../features/skills/presentation/skills_screen.dart';

/// Placeholder screen for features not yet implemented.
Widget _placeholderScreen(String title) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Centralized GoRouter configuration — from 07_flutter_architecture.md §Navigation.
///
/// Uses ShellRoute for bottom navigation on primary screens.
/// Settings sub-screens (Skills, Memory, Insights) are full-screen pushes.
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RoutePaths.connection,
  redirect: _redirectGuard,
  routes: [
    // ─── Connection (no bottom nav) ───
    GoRoute(
      path: RoutePaths.connection,
      builder: (context, state) => const ConnectionScreen(),
    ),

    // ─── Shell: Bottom Navigation ───
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => _ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: RoutePaths.chat,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChatScreen(),
          ),
        ),
        GoRoute(
          path: RoutePaths.sessions,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SessionListScreen(),
          ),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => SessionDetailScreen(
                sessionId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.tasks,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TaskListScreen(),
          ),
          routes: [
            // "new" MUST come before ":id" to prevent "new" being captured as an ID.
            GoRoute(
              path: 'new',
              builder: (context, state) => const TaskFormScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => TaskDetailScreen(
                id: state.pathParameters['id']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => TaskFormScreen(
                    id: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
          ],
        ),
        // FEATURE_GATE: BUG-N2-Workspace — /v1/workspace returns 404 from gateway.
        // Re-enable when the Hermes Agent API Server supports this endpoint.
        if (FeatureFlags.workspaceEnabled)
          GoRoute(
            path: RoutePaths.workspace,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WorkspaceScreen(),
            ),
          )
        else
          GoRoute(
            path: RoutePaths.workspace,
            pageBuilder: (context, state) => NoTransitionPage(
              child: _placeholderScreen('Workspace — Coming Soon'),
            ),
          ),
        GoRoute(
          path: RoutePaths.settings,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),

    // ─── Settings sub-screens (full-screen, no bottom nav) ───
    GoRoute(
      path: RoutePaths.skills,
      builder: (context, state) => const SkillsScreen(),
    ),
    // FEATURE_GATE: BUG-N2-Memory — /v1/memory returns 404 from gateway.
    // Re-enable when the Hermes Agent API Server supports this endpoint.
    if (FeatureFlags.memoryEnabled)
      GoRoute(
        path: RoutePaths.memory,
        builder: (context, state) => const MemoryScreen(),
      )
    else
      GoRoute(
        path: RoutePaths.memory,
        builder: (context, state) =>
            _placeholderScreen('Memory — Coming Soon'),
      ),
    // FEATURE_GATE: BUG-5-Insights — /v1/insights returns 404 from gateway.
    // Re-enable when the Hermes Agent API Server supports this endpoint.
    if (FeatureFlags.insightsEnabled)
      GoRoute(
        path: RoutePaths.insights,
        builder: (context, state) => const InsightsScreen(),
      )
    else
      GoRoute(
        path: RoutePaths.insights,
        builder: (context, state) =>
            _placeholderScreen('Insights — Coming Soon'),
      ),
    GoRoute(
      path: RoutePaths.license,
      builder: (context, state) => _placeholderScreen('License'),
    ),
    GoRoute(
      path: RoutePaths.servers,
      builder: (context, state) => const ServerListScreen(),
    ),
  ],
);

/// Shell scaffold for bottom navigation bar.
class _ShellScaffold extends StatelessWidget {
  final Widget child;

  const _ShellScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavBar(),
    );
  }
}

/// Bottom navigation bar — Chat | Sessions | Tasks | Workspace | Settings.
class _BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex;
    if (location.startsWith(RoutePaths.chat)) {
      currentIndex = 0;
    } else if (location.startsWith(RoutePaths.sessions)) {
      currentIndex = 1;
    } else if (location.startsWith(RoutePaths.tasks)) {
      currentIndex = 2;
    } else if (location.startsWith(RoutePaths.workspace)) {
      currentIndex = 3;
    } else {
      currentIndex = 4; // settings
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go(RoutePaths.chat);
          case 1:
            context.go(RoutePaths.sessions);
          case 2:
            context.go(RoutePaths.tasks);
          case 3:
            context.go(RoutePaths.workspace);
          case 4:
            context.go(RoutePaths.settings);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: 'Chat',
        ),
        NavigationDestination(
          icon: Icon(Icons.forum_outlined),
          selectedIcon: Icon(Icons.forum),
          label: 'Sessions',
        ),
        NavigationDestination(
          icon: Icon(Icons.schedule_outlined),
          selectedIcon: Icon(Icons.schedule),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.folder_outlined),
          selectedIcon: Icon(Icons.folder),
          label: 'Workspace',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}

// ─── Router Guard ────────────────────────────────────────────────────────────

/// Redirect guard: sends unauthenticated users back to /connection.
///
/// When [ConnectionStatus.idle], any ShellRoute page redirects to connection.
/// Non-ShellRoute pages (/connection, /servers, /skills, /memory, /insights,
/// /settings/license) are accessible regardless of connection state.
String? _redirectGuard(BuildContext context, GoRouterState state) {
  final container = ProviderScope.containerOf(context);
  final connState = container.read(connectionProvider);
  final location = state.uri.toString();

  if (connState.status == ConnectionStatus.idle &&
      location != RoutePaths.connection &&
      _isShellRoutePath(location)) {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: _redirectGuard → redirecting to /connection ===');
    }
    return RoutePaths.connection;
  }
  return null;
}

/// Returns true if [location] is a page inside the ShellRoute (bottom nav).
///
/// ShellRoute pages: /chat, /sessions/*, /tasks/*, /workspace, /settings
/// Excluded: /connection, /servers, /skills, /memory, /insights, /settings/license
bool _isShellRoutePath(String location) {
  // Exact-match base ShellRoute paths.
  const shellExact = {'/chat', '/workspace', '/settings'};
  if (shellExact.contains(location)) return true;
  // Sub-paths inside ShellRoute.
  if (location.startsWith('/sessions')) return true;
  if (location.startsWith('/tasks')) return true;
  return false;
}
