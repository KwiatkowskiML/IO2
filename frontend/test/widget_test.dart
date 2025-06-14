// Import necessary packages for testing and for your app's services
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/services/api_service.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/core/services/cart_service.dart';
import 'package:resellio/presentation/auth/pages/welcome_screen.dart';

void main() {
  // A test group for the Welcome Screen
  group('WelcomeScreen Tests', () {

    // A helper function to build the widget tree with necessary providers
    Widget buildTestableWidget(Widget widget) {
      return MultiProvider(
        providers: [
          Provider(create: (_) => ApiService()),
          ChangeNotifierProvider(
            create: (context) => AuthService(context.read<ApiService>()),
          ),
          ChangeNotifierProvider(
            create: (context) => CartService(context.read<ApiService>()),
          ),
        ],
        child: MaterialApp(
          home: widget,
        ),
      );
    }

    // The main test case
    testWidgets('displays branding, action buttons, and login prompt', (WidgetTester tester) async {
      // 1. Build the WelcomeScreen widget within our test environment.
      await tester.pumpWidget(buildTestableWidget(const WelcomeScreen()));

      // 2. Verify that the main branding text "RESELLIO" is present.
      // `findsOneWidget` ensures it appears exactly once.
      expect(find.text('RESELLIO'), findsOneWidget);
      
      // 3. Verify the tagline is visible.
      expect(find.text('The Ticket Marketplace'), findsOneWidget);

      // 4. Verify both registration buttons are displayed.
      expect(find.text('REGISTER AS USER'), findsOneWidget);
      expect(find.text('REGISTER AS ORGANIZER'), findsOneWidget);
      
      // 5. Verify the login prompt button is displayed.
      expect(find.text('Already have an account? Log In'), findsOneWidget);
    });
  });
}
