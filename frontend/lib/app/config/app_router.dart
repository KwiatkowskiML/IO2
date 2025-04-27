import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resellio/presentation/auth/pages/welcome_screen.dart';
import 'package:resellio/presentation/main_page/main_layout.dart';
import 'package:resellio/presentation/common_widgets/adaptive_navigation.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/welcome',
    routes: <RouteBase>[
      GoRoute(
        path: '/welcome',
        builder: (BuildContext context, GoRouterState state) {
          return const WelcomeScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {

          return Scaffold(
            appBar: AppBar(title: const Text('Login')),
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  context.go('/home/user');
                },
                child: const Text('Simulate Login (as User)'),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/user/register',
        builder: (BuildContext context, GoRouterState state) {

          return const Scaffold(body: Center(child: Text("User Registration Page")));
        },
      ),
      GoRoute(
        path: '/organizer/register',
        builder: (BuildContext context, GoRouterState state) {

          return const Scaffold(body: Center(child: Text("Organizer Registration Page")));
        },
      ),


      // This route uses a parameter to determine the user role
      GoRoute(
        path: '/home/:userType', // e.g., /home/user, /home/organizer, /home/admin
        builder: (context, state) {
          final userTypeString = state.pathParameters['userType'] ?? 'user'; // Default to 'user' if param is missing
          UserRole role;
          switch (userTypeString.toLowerCase()) {
            case 'organizer':
              role = UserRole.organizer;
              break;
            case 'admin':
              role = UserRole.admin;
              break;
            case 'user': // Fallthrough intended
            default:
              role = UserRole.user;
              break;
          }

          return MainLayout(userRole: role);
        },
      ),


    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Text('Error: The requested page "${state.uri}" could not be found.\n${state.error}'),
      ),
    ),
  );
}