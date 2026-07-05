import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/workspace/presentation/workspace_screen.dart';

/// Wraps a widget in ProviderScope and MaterialApp for testing.
Widget testableWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('WorkspaceScreen — rendering', () {
    testWidgets('renders AppBar with title', (tester) async {
      await tester.pumpWidget(testableWidget(const WorkspaceScreen()));

      expect(find.text('Workspace'), findsOneWidget);
    });

    testWidgets('renders root breadcrumb', (tester) async {
      await tester.pumpWidget(testableWidget(const WorkspaceScreen()));

      // Root breadcrumb '/' should be visible
      expect(find.text('/'), findsOneWidget);
    });

    testWidgets('renders refresh button', (tester) async {
      await tester.pumpWidget(testableWidget(const WorkspaceScreen()));

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(testableWidget(const WorkspaceScreen()));

      // Initially the FutureProvider is loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('WorkspaceScreen — empty state', () {
    // Empty state requires mocking the provider to return empty list.
    // Placeholder for integration tests when mock pattern is established.
  });

  group('WorkspaceScreen — file preview', () {
    // File preview testing requires mocking the provider.
    // Placeholder for integration tests.
  });
}
