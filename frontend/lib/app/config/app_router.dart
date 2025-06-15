import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resellio/core/models/event_model.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/auth/pages/login_screen.dart';
import 'package:resellio/presentation/auth/pages/register_screen.dart';
import 'package:resellio/presentation/auth/pages/welcome_screen.dart';
import 'package:resellio/presentation/main_page/main_layout.dart';
import 'package:resellio/presentation/common_widgets/adaptive_navigation.dart';
import 'package:resellio/presentation/events/pages/event_details_page.dart';
import 'package:resellio/presentation/cart/pages/cart_page.dart';
import 'package:resellio/presentation/organizer/pages/create_event_page.dart';
import 'package:resellio/presentation/organizer/pages/edit_event_page.dart';

class AppRouter {
  static GoRouter createRouter(AuthService authService) {
    return GoRouter(
      initialLocation: '/welcome',
      refreshListenable: authService,
      redirect: (BuildContext context, GoRouterState state) {
        final bool loggedIn = authService.isLoggedIn;
        final String? userRoleName = authService.user?.role.name;

        final bool onAuthRoute =
            state.uri.path.startsWith('/welcome') ||
            state.uri.path.startsWith('/login') ||
            state.uri.path.startsWith('/register');

        // If user is not logged in and not on an auth route, redirect to welcome
        if (!loggedIn && !onAuthRoute) {
          return '/welcome';
        }

        // If user is logged in and tries to access an auth route, redirect to home
        if (loggedIn && onAuthRoute) {
          return '/home/${userRoleName ?? 'customer'}';
        }

        // No redirect needed
        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) {
            final userType = state.uri.queryParameters['type'] ?? 'customer';
            return RegisterScreen(userType: userType);
          },
        ),

        // This route uses a parameter to determine the user role
        GoRoute(
          path: '/home/:userType',
          builder: (context, state) {
            final userTypeString =
                state.pathParameters['userType'] ?? 'customer';
            UserRole role;
            switch (userTypeString.toLowerCase()) {
              case 'organizer':
                role = UserRole.organizer;
                break;
              case 'admin':
                role = UserRole.admin;
                break;
              default:
                role = UserRole.customer;
                break;
            }
            return MainLayout(userRole: role);
          },
        ),

        GoRoute(
          path: '/event/:id',
          builder: (context, state) {
            final event = state.extra as Event?;
            final eventId = state.pathParameters['id'];

            if (event != null) {
              return EventDetailsPage(event: event);
            } else if (eventId != null) {
              // If event is not passed, fetch it by ID
              return EventDetailsPage(eventId: int.tryParse(eventId));
            } else {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Event ID is missing.')),
              );
            }
          },
        ),
        GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
        GoRoute(
            path: '/organizer/create-event',
            builder: (context, state) => const CreateEventPage()),
        GoRoute(
            path: '/organizer/edit-event/:id',
            builder: (context, state) {
              final event = state.extra as Event?;
              if (event == null) {
                 return Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: const Center(child: Text('Event data is missing.')),
                );
              }
              return EditEventPage(event: event);
            }),
      ],
      errorBuilder:
          (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Text(
                'Error: The requested page "${state.uri}" could not be found.\n${state.error}',
              ),
            ),
          ),
    );
  }
}
