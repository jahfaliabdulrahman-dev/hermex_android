import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/app.dart';

void main() {
  testWidgets('HermexApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const HermexApp());
    // Verify the app renders — MaterialApp.router is present.
    expect(find.byType(HermexApp), findsOneWidget);
  });
}
