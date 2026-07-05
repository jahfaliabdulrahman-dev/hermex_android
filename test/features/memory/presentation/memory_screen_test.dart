import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/memory/presentation/memory_screen.dart';
import 'package:hermex_android/features/memory/providers/memory_provider.dart';
import 'package:hermex_android/models/memory_entry.dart';

/// Helper to wrap a widget in ProviderScope with overrides.
Widget _buildTestApp({
  List<MemoryEntry>? entries,
  Object? error,
}) {
  return ProviderScope(
    overrides: [
      memoryListProvider.overrideWith((ref) {
        if (error != null) throw error;
        return entries ?? [];
      }),
    ],
    child: const MaterialApp(
      home: MemoryScreen(),
    ),
  );
}

void main() {
  group('MemoryScreen', () {
    testWidgets('shows empty state when no memories', (tester) async {
      await tester.pumpWidget(_buildTestApp(entries: []));
      await tester.pumpAndSettle();

      expect(find.text('No memories stored'), findsOneWidget);
      expect(
          find.text('The agent will save facts as it learns about you.'),
          findsOneWidget);
    });

    testWidgets('shows memory entries when data is available', (tester) async {
      // Use recent timestamps to avoid intl DateFormat initialization issues.
      final now = DateTime.now();
      final entries = [
        MemoryEntry(
          id: '1',
          title: 'User prefers dark mode',
          description: 'The user has expressed a preference.',
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
        MemoryEntry(
          id: '2',
          title: 'User location Riyadh',
          description: 'Based in Saudi Arabia.',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
      ];

      await tester.pumpWidget(_buildTestApp(entries: entries));
      await tester.pumpAndSettle();

      expect(find.text('User prefers dark mode'), findsOneWidget);
      expect(find.text('User location Riyadh'), findsOneWidget);
      expect(find.text('The user has expressed a preference.'), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(error: Exception('Network error')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load memory'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('search filters entries', (tester) async {
      final now = DateTime.now();
      final entries = [
        MemoryEntry(
            id: '1',
            title: 'User prefers dark mode',
            createdAt: now),
        MemoryEntry(
            id: '2',
            title: 'User location Riyadh',
            createdAt: now),
      ];

      await tester.pumpWidget(_buildTestApp(entries: entries));
      await tester.pumpAndSettle();

      // Type search query
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'dark');
      await tester.pumpAndSettle();

      // Only matching entry should be visible
      expect(find.text('User prefers dark mode'), findsOneWidget);
      expect(find.text('User location Riyadh'), findsNothing);
    });

    testWidgets('clear search shows all entries again', (tester) async {
      final now = DateTime.now();
      final entries = [
        MemoryEntry(
            id: '1',
            title: 'User prefers dark mode',
            createdAt: now),
        MemoryEntry(
            id: '2',
            title: 'User location Riyadh',
            createdAt: now),
      ];

      await tester.pumpWidget(_buildTestApp(entries: entries));
      await tester.pumpAndSettle();

      // Type and clear
      await tester.enterText(find.byType(TextField), 'dark');
      await tester.pumpAndSettle();
      expect(find.text('User prefers dark mode'), findsOneWidget);

      // Clear
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('User prefers dark mode'), findsOneWidget);
      expect(find.text('User location Riyadh'), findsOneWidget);
    });

    testWidgets('shows "no matches" when search has no results',
        (tester) async {
      final entries = [
        MemoryEntry(
            id: '1',
            title: 'User prefers dark mode',
            createdAt: DateTime.now()),
      ];

      await tester.pumpWidget(_buildTestApp(entries: entries));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pumpAndSettle();

      expect(find.textContaining('No memories match'), findsOneWidget);
    });
  });
}
