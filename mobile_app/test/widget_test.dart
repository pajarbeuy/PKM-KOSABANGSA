import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/main.dart';
import 'package:mobile_app/providers/auth_provider.dart';

void main() {
  testWidgets('SIMHPSK App displays landing screen when not authenticated', 
    (WidgetTester tester) async {
      // Build the app with a mock AuthProvider
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: const MyApp(),
        ),
      );

      // Wait for the app to build
      await tester.pumpAndSettle();

      // Verify landing screen is displayed (not authenticated)
      expect(
        find.text('SIMHPSK'),
        findsOneWidget,
        reason: 'App should show SIMHPSK title on landing screen',
      );
    },
  );

  testWidgets('SIMHPSK App has proper Material app structure',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify the app is a MaterialApp
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Verify Material3 design is enabled
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, isTrue);
    },
  );
}
