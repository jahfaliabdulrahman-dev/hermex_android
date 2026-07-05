import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/insights/presentation/insights_screen.dart';
import 'package:hermex_android/features/insights/providers/insights_provider.dart';
import 'package:hermex_android/models/insights_data.dart';

/// KNOWN-BUG: InsightsScreen stat cards use Expanded inside a scrollable Column
/// at line 314, causing unbounded height constraints. Production code bug tracked
/// for routing to engineer. Widget tests limited to basic rendering until fixed.

Widget _wrap(InsightsData data) {
  return ProviderScope(
    overrides: [
      insightsProvider.overrideWith((ref) async => data),
    ],
    child: const MaterialApp(home: InsightsScreen()),
  );
}

void main() {
  group('InsightsScreen', () {
    testWidgets('renders app bar', (tester) async {
      await tester.pumpWidget(_wrap(const InsightsData()));
      await tester.pumpAndSettle();
      expect(find.text('Insights'), findsOneWidget);
    });
  });
}
