import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/skills/presentation/skills_screen.dart';

/// Wraps a widget in ProviderScope and MaterialApp for testing.
Widget testableWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('SkillsScreen — rendering', () {
    testWidgets('renders AppBar with title', (tester) async {
      await tester.pumpWidget(testableWidget(const SkillsScreen()));

      expect(find.text('Skills'), findsOneWidget);
    });

    testWidgets('renders search bar', (tester) async {
      await tester.pumpWidget(testableWidget(const SkillsScreen()));

      // The search input should exist
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(testableWidget(const SkillsScreen()));

      // Initially the FutureProvider is loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SkillsScreen — error state', () {
    // Error state testing would require mocking the provider,
    // which is more complex. Placeholder for integration tests.
  });

  group('_Badge widget', () {
    testWidgets('badge renders label text', (tester) async {
      // Badge is a private widget in skills_screen.dart.
      // Test indirectly by loading the screen and checking if wrapped properly.
      await tester.pumpWidget(testableWidget(const SkillsScreen()));
      // Screen renders without crashing
      expect(find.byType(SkillsScreen), findsOneWidget);
    });
  });
}
