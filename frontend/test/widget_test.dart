import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/app/config/app_router.dart';
import 'package:resellio/core/models/cart_model.dart';
import 'package:resellio/core/network/api_client.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/auth/pages/welcome_screen.dart';
import 'package:resellio/presentation/cart/cubit/cart_cubit.dart';

// Mock implementation of CartRepository to be used in tests, preventing network calls.
class MockCartRepository extends Fake implements CartRepository {
  @override
  Future<List<CartItem>> getCartItems() async => [];

  @override
  Future<void> addToCart(int ticketTypeId, int quantity) async {}

  @override
  Future<void> addResaleTicketToCart(int ticketId) async {}

  @override
  Future<void> removeFromCart(int cartItemId) async {}

  @override
  Future<bool> checkout() async => true;
}

// A mock router for testing navigation from WelcomeScreen
final GoRouter _router = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder:
          (context, state) =>
              const Scaffold(body: Center(child: Text('Mock Login Page'))),
    ),
    GoRoute(
      path: '/register',
      builder:
          (context, state) =>
              const Scaffold(body: Center(child: Text('Mock Register Page'))),
    ),
  ],
);

void main() {
  testWidgets(
    'WelcomeScreen should display UI elements and handle navigation',
    (WidgetTester tester) async {
      // Build our app with the mock router.
      await tester.pumpWidget(MaterialApp.router(routerConfig: _router));

      // 1. Verify that the main UI elements are present.
      expect(
        find.text('RESELLIO'),
        findsOneWidget,
        reason: 'App title should be visible',
      );
      expect(
        find.text('The Ticket Marketplace'),
        findsOneWidget,
        reason: 'App tagline should be visible',
      );
      expect(
        find.text('REGISTER AS USER'),
        findsOneWidget,
        reason: 'Register as user button should be visible',
      );
      expect(
        find.text('REGISTER AS ORGANIZER'),
        findsOneWidget,
        reason: 'Register as organizer button should be visible',
      );
      expect(
        find.text('Already have an account? Log In'),
        findsOneWidget,
        reason: 'Login prompt should be visible',
      );

      // 2. Test navigation for "REGISTER AS USER" button.
      await tester.tap(find.text('REGISTER AS USER'));
      await tester
          .pumpAndSettle(); // Wait for navigation transition to complete.

      // Verify we navigated to the mock register page.
      expect(find.text('Mock Register Page'), findsOneWidget);

      // Navigate back to the welcome screen.
      GoRouter.of(
        tester.element(find.text('Mock Register Page')),
      ).go('/welcome');
      await tester.pumpAndSettle();

      // 3. Test navigation for "REGISTER AS ORGANIZER" button.
      await tester.tap(find.text('REGISTER AS ORGANIZER'));
      await tester.pumpAndSettle();

      // Verify we navigated to the mock register page again.
      expect(find.text('Mock Register Page'), findsOneWidget);
      GoRouter.of(
        tester.element(find.text('Mock Register Page')),
      ).go('/welcome');
      await tester.pumpAndSettle();

      // 4. Test navigation for the login prompt.
      await tester.tap(find.text('Already have an account? Log In'));
      await tester.pumpAndSettle();

      // Verify we navigated to the mock login page.
      expect(find.text('Mock Login Page'), findsOneWidget);
    },
  );
}
