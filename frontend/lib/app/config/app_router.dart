// Update your existing app_router.dart file with these changes:

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
// Import admin pages
import 'package:resellio/presentation/admin/pages/admin_user_management_page.dart';
import 'package:resellio/presentation/admin/pages/admin_organizer_verification_page.dart';
import 'package:resellio/presentation/admin/pages/admin_event_authorization_page.dart';

class AppRouter {
  static GoRouter createRouter(AuthService authService) {
    return GoRouter(
      initialLocation: '/welcome',
      refreshListenable: authService,
      redirect: (BuildContext context, GoRouterState state) {
        final bool loggedIn = authService.isLoggedIn;
        final String? userRoleName = authService.user?.role.name;
        final bool isAdmin = authService.hasAdminPrivileges;

        final bool onAuthRoute =
            state.uri.path.startsWith('/welcome') ||
                state.uri.path.startsWith('/login') ||
                state.uri.path.startsWith('/register');

        final bool onAdminRoute = state.uri.path.startsWith('/admin');

        // If user is not logged in and not on an auth route, redirect to welcome
        if (!loggedIn && !onAuthRoute) {
          return '/welcome';
        }

        // If user is logged in and tries to access an auth route, redirect to home
        if (loggedIn && onAuthRoute) {
          return '/home/${userRoleName ?? 'customer'}';
        }

        // If non-admin user tries to access admin routes, redirect to their home
        if (onAdminRoute && !isAdmin) {
          return '/home/${userRoleName ?? 'customer'}';
        }

        // No redirect needed
        return null;
      },
      routes: <RouteBase>[
        // Auth routes
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

        // Main app routes
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
              case 'administrator':
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

        // Event details route
        GoRoute(
          path: '/event/:id',
          builder: (context, state) {
            final event = state.extra as Event?;
            final eventId = state.pathParameters['id'];

            if (event != null) {
              return EventDetailsPage(event: event);
            } else if (eventId != null) {
              return EventDetailsPage(eventId: int.tryParse(eventId));
            } else {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Event ID is missing.')),
              );
            }
          },
        ),

        // Cart route
        GoRoute(
          path: '/cart',
          builder: (context, state) => const CartPage(),
        ),

        // Admin routes
        GoRoute(
          path: '/admin',
          redirect: (context, state) => '/admin/dashboard',
        ),
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => MainLayout(userRole: UserRole.admin),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const AdminUserManagementPage(),
        ),
        GoRoute(
          path: '/admin/organizers',
          builder: (context, state) => const AdminOrganizerVerificationPage(),
        ),
        GoRoute(
          path: '/admin/events',
          builder: (context, state) => const AdminEventAuthorizationPage(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
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