import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/sessions/presentation/session_list_screen.dart';
import 'package:hermex_android/features/sessions/providers/session_provider.dart';
import 'package:hermex_android/features/sessions/data/session_repository.dart';
import 'package:hermex_android/models/session_summary.dart';
import 'package:hermex_android/core/constants/app_strings.dart';

/// Helper to create a testable SessionListScreen with provider overrides.
Widget createTestableSessionListScreen({
  List<SessionSummary>? sessions,
  Object? error,
  bool isLoading = false,
  Completer<SessionListPage>? loadingCompleter,
}) {
  return ProviderScope(
    overrides: [
      sessionListProvider.overrideWith((ref) {
        if (isLoading && loadingCompleter != null) {
          return loadingCompleter.future;
        }
        if (error != null) {
          return Future.error(error);
        }
        return Future.value(SessionListPage(sessions: sessions ?? []));
      }),
    ],
    child: const MaterialApp(
      home: SessionListScreen(),
    ),
  );
}

void main() {
  group('SessionListScreen — Loading State', () {
    testWidgets('shows skeleton loading cards while fetching', (tester) async {
      final completer = Completer<SessionListPage>();

      await tester.pumpWidget(createTestableSessionListScreen(
        isLoading: true,
        loadingCompleter: completer,
      ));
      await tester.pump();

      // The loading state renders skeleton Cards with surface color.
      final cards = find.byType(Card);
      expect(cards, findsWidgets);
    });
  });

  group('SessionListScreen — Empty State', () {
    testWidgets('shows empty state message', (tester) async {
      await tester.pumpWidget(createTestableSessionListScreen(sessions: []));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noSessionsYet), findsOneWidget);
      expect(find.text(AppStrings.startChatForFirstSession), findsOneWidget);
    });

    testWidgets('shows new chat button', (tester) async {
      await tester.pumpWidget(createTestableSessionListScreen(sessions: []));
      await tester.pumpAndSettle();

      // "New Chat" text appears in both the FAB and the empty state button.
      expect(find.text('New Chat'), findsAtLeast(1));
    });
  });

  group('SessionListScreen — Error State', () {
    testWidgets('shows error message with retry button', (tester) async {
      await tester.pumpWidget(
        createTestableSessionListScreen(error: Exception('Server error')),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.failedToLoadSessions), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
    });
  });

  group('SessionListScreen — Success State', () {
    testWidgets('displays active session titles (not archived)', (tester) async {
      final sessions = [
        SessionSummary(
          id: 's1',
          title: 'Test Session 1',
          modelName: 'deepseek-v4',
          messageCount: 10,
          lastActivity: DateTime.now(),
        ),
        SessionSummary(
          id: 's2',
          title: 'Pinned Session',
          modelName: 'qwen-max',
          messageCount: 5,
          lastActivity: DateTime.now(),
          isPinned: true,
        ),
      ];

      await tester.pumpWidget(createTestableSessionListScreen(sessions: sessions));
      await tester.pumpAndSettle();

      // Active sessions should be visible.
      expect(find.text('Test Session 1'), findsOneWidget);
      expect(find.text('Pinned Session'), findsOneWidget);
    });

    testWidgets('archived sessions are hidden by default', (tester) async {
      final sessions = [
        SessionSummary(
          id: 's3',
          title: 'Hidden Archived',
          messageCount: 2,
          lastActivity: DateTime.now(),
          isArchived: true,
        ),
      ];

      await tester.pumpWidget(createTestableSessionListScreen(sessions: sessions));
      await tester.pumpAndSettle();

      // Archived sessions should be hidden when showArchived is false.
      expect(find.text('Hidden Archived'), findsNothing);
    });

    testWidgets('shows pin icon for pinned sessions', (tester) async {
      final sessions = [
        SessionSummary(
          id: 's1',
          title: 'Pinned',
          messageCount: 1,
          lastActivity: DateTime.now(),
          isPinned: true,
        ),
      ];

      await tester.pumpWidget(createTestableSessionListScreen(sessions: sessions));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('shows model name and message count', (tester) async {
      final sessions = [
        SessionSummary(
          id: 's1',
          title: 'Test',
          modelName: 'gpt-4',
          messageCount: 42,
          lastActivity: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(createTestableSessionListScreen(sessions: sessions));
      await tester.pumpAndSettle();

      expect(find.text('gpt-4'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('truncates long titles to 80 chars with ellipsis', (tester) async {
      final longTitle = 'A' * 200;
      final sessions = [
        SessionSummary(
          id: 's1',
          title: longTitle,
          messageCount: 1,
          lastActivity: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(createTestableSessionListScreen(sessions: sessions));
      await tester.pumpAndSettle();

      final truncatedTitle = '${longTitle.substring(0, 80)}…';
      expect(find.text(truncatedTitle), findsOneWidget);
      expect(find.text(longTitle), findsNothing);
    });
  });

  group('SessionListScreen — Search Bar', () {
    testWidgets('shows search text field with correct hint', (tester) async {
      await tester.pumpWidget(createTestableSessionListScreen(sessions: []));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(AppStrings.searchSessions), findsOneWidget);
    });
  });

  group('SessionListScreen — FAB', () {
    testWidgets('shows New Chat FAB when sessions are loaded', (tester) async {
      await tester.pumpWidget(createTestableSessionListScreen(sessions: []));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('SessionListScreen — Active Status', () {
    testWidgets('renders active session without crashing', (tester) async {
      final sessions = [
        SessionSummary(
          id: 's1',
          title: 'Active Session',
          messageCount: 1,
          lastActivity: DateTime.now(),
          status: 'active',
        ),
      ];

      await tester.pumpWidget(createTestableSessionListScreen(sessions: sessions));
      await tester.pumpAndSettle();

      // Just verify the session renders.
      expect(find.text('Active Session'), findsOneWidget);
    });
  });
}
