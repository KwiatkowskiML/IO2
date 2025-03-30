import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resellio/presentation/common_widgets/primary_button.dart';

class WelcomeActionButtons extends StatelessWidget {
  const WelcomeActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          text: 'REGISTER AS USER',
          onPressed: () => GoRouter.of(context).push('/user/register'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: 'REGISTER AS ORGANIZER',
          onPressed: () => GoRouter.of(context).push('/organizer/register'),
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
        ),
      ],
    );
  }
}