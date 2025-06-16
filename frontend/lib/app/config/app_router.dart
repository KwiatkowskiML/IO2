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
import 'package:resellio/core/models/user_model.dart';
import 'package:resellio/presentation/admin/pages/admin_dashboard_page.dart';
import 'package:resellio/presentation/organizer/pages/create_event_page.dart';
import 'package:resellio/presentation/organizer/pages/edit_event_page.dart';

class AppRouter {
  static GoRouter createRouter(AuthService authService) {
    return GoRouter(
      initialLocation: '/welcome',
      refreshListenable: authService,
      redirect: (BuildContext context, GoRouterState state) {
        final bool loggedIn = authService.isLoggedIn;
        final user = authService.user;

        // Get the user role - handle both enum and string cases
        String? userRoleName;
        if (user != null) {
          // Check if role is an enum (UserRole) or string
          if (user.role is UserRole) {
            userRoleName = (user.role as UserRole).name;
          } else {
            userRoleName = user.role.toString();
          }
        }

        final bool onAuthRoute =
            state.uri.path.startsWith('/welcome') ||
                state.uri.path.startsWith('/login') ||
                state.uri.path.startsWith('/register');

        final bool onAdminRoute = state.uri.path.startsWith('/admin');

        // If user is not logged in and not on an auth route, redirect to welcome
        if (!loggedIn && !onAuthRoute) {
          return '/welcome';
        }

        // If user is logged in and tries to access an auth route, redirect based on role
        if (loggedIn && onAuthRoute) {
          // Check for administrator role (handle different possible values)
          if (userRoleName == 'administrator' || userRoleName == 'admin') {
            return '/admin';
          }
          return '/home/${userRoleName ?? 'customer'}';
        }

        // If non-admin user tries to access admin routes, redirect to their home
        if (loggedIn && onAdminRoute && userRoleName != 'administrator' && userRoleName != 'admin') {
          return '/home/${userRoleName ?? 'customer'}';
        }

        // No redirect needed
        return null;
      },
      routes: <RouteBase>[
        // Auth Routes
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

        // Admin Routes with Sidebar Navigation
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminMainPage(initialTab: 'overview'),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const AdminMainPage(initialTab: 'users'),
        ),
        GoRoute(
          path: '/admin/organizers',
          builder: (context, state) => const AdminMainPage(initialTab: 'organizers'),
        ),
        GoRoute(
          path: '/admin/events',
          builder: (context, state) => const AdminMainPage(initialTab: 'events'),
        ),
        GoRoute(
          path: '/admin/add-admin',
          builder: (context, state) => const AdminMainPage(initialTab: 'add-admin'),
        ),
        GoRoute(
          path: '/admin/verification',
          builder: (context, state) => const AdminMainPage(initialTab: 'verification'),
        ),

        // Main App Routes
        GoRoute(
          path: '/home/:userType',
          builder: (context, state) {
            final userTypeString = state.pathParameters['userType'] ?? 'customer';
            UserRole role;

            switch (userTypeString.toLowerCase()) {
              case 'organizer':
                role = UserRole.organizer;
                break;
              case 'administrator':
              case 'admin':
              // Redirect admin users to admin panel
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/admin');
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              default:
                role = UserRole.customer;
                break;
            }
            return MainLayout(userRole: role);
          },
        ),

        // Event Routes
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
