import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/core/models/user_model.dart';
import 'package:resellio/presentation/common_widgets/adaptive_navigation.dart';

class MainLayout extends StatelessWidget {
  final UserRole userRole;

  const MainLayout({
    super.key,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    // Listen to AuthService to rebuild if the user logs out.
    final authService = context.watch<AuthService>();

    // If the user logs out, authService.user will be null.
    // The GoRouter redirect will handle navigation, but as a fallback,
    // we can show a loading indicator or an empty container.
    if (!authService.isLoggedIn) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AdaptiveNavigation(
      userRole: userRole,
      body: Container(),
    );
  }
}
