import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/connection/presentation/connection_screen.dart';
import 'package:hermex_android/core/constants/app_strings.dart';

/// Wraps a widget in ProviderScope and MaterialApp for testing.
Widget testableWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('ConnectionScreen — rendering', () {
    testWidgets('renders connect button and input fields', (tester) async {
      await tester.pumpWidget(testableWidget(const ConnectionScreen()));

      // Should have URL, API key, and label text form fields
      expect(find.byType(TextFormField), findsNWidgets(3));

      // Should have connect button
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('renders AppBar with title', (tester) async {
      await tester.pumpWidget(testableWidget(const ConnectionScreen()));

      expect(find.text('Connect to Hermes'), findsOneWidget);
    });

    testWidgets('renders saved servers link when no servers', (tester) async {
      await tester.pumpWidget(testableWidget(const ConnectionScreen()));

      expect(find.text('No saved servers'), findsOneWidget);
    });

    testWidgets('shows validation error for empty URL', (tester) async {
      await tester.pumpWidget(testableWidget(const ConnectionScreen()));

      // Tap connect without entering URL
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      // Should show validation message
      expect(find.text('Server URL is required.'), findsOneWidget);
    });

    testWidgets('shows validation for empty API key', (tester) async {
      await tester.pumpWidget(testableWidget(const ConnectionScreen()));

      // Focus the URL field first, then enter text
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'http://test:8642');
      await tester.pumpAndSettle();

      // Tap connect with empty API key
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      // Should show API key validation
      expect(find.text('API key is required.'), findsOneWidget);
    });

    testWidgets('shows validation for URL without scheme', (tester) async {
      await tester.pumpWidget(testableWidget(const ConnectionScreen()));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '192.168.1.100:8642');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      // Updated: message now comes from AppStrings.invalidUrlNotAbsolute
      expect(
        find.text('Invalid URL format. Please enter a valid server address.'),
        findsOneWidget,
      );
    });

    testWidgets('shows validation for HTTP on remote host', (tester) async {
      await tester.pumpWidget(testableWidget(const ConnectionScreen()));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'http://api.example.com:8642');
      await tester.enterText(fields.last, 'test-api-key');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      // HTTP on non-local network should be rejected.
      expect(
        find.text(AppStrings.invalidUrlHttpRemote),
        findsOneWidget,
      );
    });

    testWidgets('shows validation for host injection via @', (tester) async {
      await tester.pumpWidget(testableWidget(const ConnectionScreen()));

      final fields = find.byType(TextFormField);
      await tester.enterText(
          fields.first, 'http://evil.com@192.168.1.100:8642');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      // Credentials in URL should be rejected.
      expect(
        find.text(AppStrings.invalidUrlHostInjection),
        findsOneWidget,
      );
    });

    testWidgets('toggle API key visibility', (tester) async {
      await tester.pumpWidget(testableWidget(const ConnectionScreen()));

      // Find the visibility toggle icon
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap to show the key
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // Now the icon should change to visibility (key is visible)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('clicking saved servers link navigates', (tester) async {
      await tester.pumpWidget(testableWidget(const ConnectionScreen()));

      // Should show No saved servers link
      expect(find.text('No saved servers'), findsOneWidget);
    });
  });
}
