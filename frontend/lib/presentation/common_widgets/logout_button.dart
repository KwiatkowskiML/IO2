import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LogoutButton extends StatelessWidget {
  final bool isExtended;

  const LogoutButton({super.key, this.isExtended = false});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement actual logout logic (clear session, etc.)
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Logout',
      onPressed: () {
        GoRouter.of(context).go('/welcome');
      },
    );
  }
}