import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/services/auth_service.dart';

class LogoutButton extends StatelessWidget {
  final bool isExtended;

  const LogoutButton({super.key, this.isExtended = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Logout',
      onPressed: () {
        context.read<AuthService>().logout();
      },
    );
  }
}
