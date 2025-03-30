import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resellio/presentation/main_page/main_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/welcome', // Start at the welcome screen
    routes: <RouteBase>[
      GoRoute(
        path: '/welcome',
        builder: (BuildContext context, GoRouterState state) {
          return const WelcomeScreen();
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}