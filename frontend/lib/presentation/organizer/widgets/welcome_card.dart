import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/services/auth_service.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.user;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, ${user?.name ?? 'Organizer'}!',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Here\'s an overview of your events and activities.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
