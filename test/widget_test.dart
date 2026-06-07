import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter_app/pages/home_page.dart';

void main() {
  testWidgets('HomePage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );

    // Verify the header text is present
    expect(find.text('Malayanmods'), findsOneWidget);
    expect(find.text('Something awesome is brewing'), findsOneWidget);

    // Verify the Coming Soon card is present
    expect(find.text('Coming Soon'), findsOneWidget);

    // Verify the TMS7 Viewer card is present
    expect(find.text('TMS7 3D Viewer'), findsOneWidget);
  });
}
