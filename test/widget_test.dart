import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter_app/pages/home_page.dart';
import 'package:supabase_flutter_app/theme/app_theme.dart';

void main() {
  testWidgets('HomePage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const HomePage(),
      ),
    );

    // Verify the header text is present
    expect(find.text('Supabase + Flutter'), findsOneWidget);
    expect(find.text('Your project is ready to launch'), findsOneWidget);

    // Verify the action button is present
    expect(find.text('Test Supabase Connection'), findsOneWidget);

    // Verify the info cards are present
    expect(find.text('Configure'), findsOneWidget);
    expect(find.text('Database'), findsOneWidget);
    expect(find.text('Deploy'), findsOneWidget);
  });
}
