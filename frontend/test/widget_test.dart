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

void main() {
  // A helper function to build a widget tree with all necessary providers for testing.
  // This mimics the setup in `main.dart` but can use mock implementations.
  Widget buildTestableApp() {
    // For widget tests, it's best to use a mock ApiClient to avoid real network calls.
    final apiClient = ApiClient('http://mock-api.com');

    // Instantiate repositories with the mock client.
    final authRepo = ApiAuthRepository(apiClient);
    final userRepo = ApiUserRepository(apiClient);
    final eventRepo = ApiEventRepository(apiClient);
    final cartRepo = MockCartRepository(); // Use a simple mock for the cart
    final ticketRepo = ApiTicketRepository(apiClient);
    final resaleRepo = ApiResaleRepository(apiClient);
    final adminRepo = ApiAdminRepository(apiClient);

    // Instantiate services that depend on repositories.
    final authService = AuthService(authRepo, userRepo);

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthRepository>.value(value: authRepo),
        Provider<UserRepository>.value(value: userRepo),
        Provider<EventRepository>.value(value: eventRepo),
        Provider<CartRepository>.value(value: cartRepo),
        Provider<TicketRepository>.value(value: ticketRepo),
        Provider<ResaleRepository>.value(value: resaleRepo),
        Provider<AdminRepository>.value(value: adminRepo),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        BlocProvider<CartCubit>(
          create: (context) => CartCubit(context.read<CartRepository>()),
        ),
      ],
      // The app uses GoRouter, so we must wrap the test in a MaterialApp.router
      // to correctly handle navigation and screen building.
      child: MaterialApp.router(
        routerConfig: AppRouter.createRouter(authService),
      ),
    );
  }

  testWidgets('App starts and shows WelcomeScreen correctly',
      (WidgetTester tester) async {
    // Build the entire application widget tree.
    await tester.pumpWidget(buildTestableApp());

    // Allow the router to process the initial route and build the page.
    await tester.pumpAndSettle();

    // 1. Verify that the WelcomeScreen is the current screen.
    expect(find.byType(WelcomeScreen), findsOneWidget);

    // 2. Verify that the main branding title is displayed.
    expect(find.text('RESELLIO'), findsOneWidget);

    // 3. Verify that both registration buttons are visible.
    expect(find.widgetWithText(ElevatedButton, 'REGISTER AS USER'),
        findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'REGISTER AS ORGANIZER'),
        findsOneWidget);

    // 4. Verify that the login prompt button is visible.
    expect(find.widgetWithText(TextButton, 'Already have an account? Log In'),
        findsOneWidget);
  });
}
