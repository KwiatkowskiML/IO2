import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPromptButton extends StatelessWidget {
  const LoginPromptButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        GoRouter.of(context).push('/login');
      },
      child: Text(
        'Already have an account? Log In',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}