import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_paths.dart';
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
            child: _ChatPlaceholder(),
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
        GoRoute(
          path: RoutePaths.workspace,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: _WorkspacePlaceholder(),
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
      builder: (context, state) => _placeholderScreen('Skills'),
    ),
    GoRoute(
      path: RoutePaths.memory,
      builder: (context, state) => const MemoryScreen(),
    ),
    GoRoute(
      path: RoutePaths.insights,
      builder: (context, state) => const InsightsScreen(),
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

// ─── Placeholder screen widgets (to be replaced by future tasks) ───

class _ChatPlaceholder extends StatelessWidget {
  const _ChatPlaceholder();

  @override
  Widget build(BuildContext context) => _placeholderScreen('Chat');
}

class _WorkspacePlaceholder extends StatelessWidget {
  const _WorkspacePlaceholder();

  @override
  Widget build(BuildContext context) => _placeholderScreen('Workspace');
}
