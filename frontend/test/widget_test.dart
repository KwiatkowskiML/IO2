import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:resellio/main.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/cart/cubit/cart_cubit.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<String> login(String email, String password) async => 'fake_token';
  @override
  Future<void> logout() async {}
  @override
  Future<String> registerCustomer(Map<String, dynamic> data) async =>
      'fake_token';
  @override
  Future<String> registerOrganizer(Map<String, dynamic> data) async =>
      'fake_token';
}

class FakeEventRepository implements EventRepository {
  @override
  Future<List<Event>> getEvents() async => [];
  @override
  Future<List<Event>> getOrganizerEvents(int organizerId) async => [];
  @override
  Future<List<TicketType>> getTicketTypesForEvent(int eventId) async => [];
}

class FakeCartRepository implements CartRepository {
  @override
  Future<void> addResaleTicketToCart(int ticketId) async {}
  @override
  Future<void> addToCart(int ticketTypeId, int quantity) async {}
  @override
  Future<bool> checkout() async => true;
  @override
  Future<List<CartItem>> getCartItems() async => [];
  @override
  Future<void> removeFromCart(int cartItemId) async {}
}

class FakeTicketRepository implements TicketRepository {
  @override
  Future<void> cancelResaleListing(int ticketId) async {}
  @override
  Future<List<TicketDetailsModel>> getMyTickets() async => [];
  @override
  Future<void> listTicketForResale(int ticketId, double price) async {}
}

class FakeResaleRepository implements ResaleRepository {
  @override
  Future<List<ResaleTicketListing>> getMarketplaceListings(
          {int? eventId, double? minPrice, double? maxPrice}) async =>
      [];
  @override
  Future<List<ResaleTicketListing>> getMyResaleListings() async => [];
  @override
  Future<TicketDetailsModel> purchaseResaleTicket(int ticketId) async {
    return TicketDetailsModel(ticketId: ticketId, eventName: 'Fake Event');
  }
}

class FakeUserRepository implements UserRepository {
  @override
  Future<UserProfile> getUserProfile() async {
    return UserProfile(
      userId: 1,
      email: 'fake@test.com',
      firstName: 'Fake',
      lastName: 'User',
      userType: 'customer',
      isActive: true,
    );
  }

  @override
  Future<UserProfile> updateUserProfile(
      Map<String, dynamic> profileData) async {
    return UserProfile(
      userId: 1,
      email: 'fake@test.com',
      firstName: profileData['first_name'],
      lastName: profileData['last_name'],
      userType: 'customer',
      isActive: true,
    );
  }
}

class FakeAdminRepository implements AdminRepository {
  @override
  Future<void> banUser(int userId) async {}
  @override
  Future<List<UserDetails>> getAllUsers() async => [];
  @override
  Future<List<PendingOrganizer>> getPendingOrganizers() async => [];
  @override
  Future<void> unbanUser(int userId) async {}
  @override
  Future<void> verifyOrganizer(int organizerId, bool approve) async {}
}

void main() {
  testWidgets('App starts and shows WelcomeScreen', (WidgetTester tester) async {
    final fakeAuthRepo = FakeAuthRepository();
    final authService = AuthService(fakeAuthRepo, FakeUserRepository());
    final cartCubit = CartCubit(FakeCartRepository());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => ApiService()),
          ChangeNotifierProvider(
            create: (context) => AuthService(context.read<ApiService>()),
          ),
          ChangeNotifierProvider(
            create: (context) => CartService(context.read<ApiService>()),
          ),
        ],
        child: MaterialApp(home: widget),
      );
    }

    // The main test case
    testWidgets('displays branding, action buttons, and login prompt', (
      WidgetTester tester,
    ) async {
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
          Provider<AuthRepository>.value(value: fakeAuthRepo),
          Provider<UserRepository>.value(value: FakeUserRepository()),
          Provider<EventRepository>.value(value: FakeEventRepository()),
          Provider<CartRepository>.value(value: FakeCartRepository()),
          Provider<TicketRepository>.value(value: FakeTicketRepository()),
          Provider<ResaleRepository>.value(value: FakeResaleRepository()),
          Provider<AdminRepository>.value(value: FakeAdminRepository()),
          ChangeNotifierProvider<AuthService>.value(value: authService),
          BlocProvider<CartCubit>.value(value: cartCubit),
        ],
        child: const ResellioApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('REGISTER AS USER'), findsOneWidget);
    expect(find.text('REGISTER AS ORGANIZER'), findsOneWidget);
    expect(find.text('Already have an account? Log In'), findsOneWidget);
  });
}
