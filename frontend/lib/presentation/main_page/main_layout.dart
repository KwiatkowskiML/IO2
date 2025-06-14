import 'package:flutter/material.dart';
import 'package:resellio/presentation/common_widgets/adaptive_navigation.dart';

class MainLayout extends StatelessWidget {
  final UserRole userRole;

  const MainLayout({
    super.key,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigation(
      userRole: userRole,
      body: const SizedBox.shrink(),
    );
  }
}
