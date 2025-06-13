import 'package:flutter/material.dart';
import 'package:resellio/core/utils/responsive_layout.dart';
import 'package:resellio/presentation/auth/widgets/app_branding.dart';
import 'package:resellio/presentation/auth/widgets/login_prompt_button.dart';
import 'package:resellio/presentation/auth/widgets/welcome_action_buttons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1200 : 800,
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
                  child: isDesktop
                      ? _buildDesktopLayout(context)
                      : _buildMobileLayout(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage(BuildContext context, {TextAlign alignment = TextAlign.center}) {
    return Text(
      'Discover and resell tickets for amazing events. Join our community and experience the best in live entertainment.',
      textAlign: alignment,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  // --- Layout Builders ---

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const AppBranding(),
        const SizedBox(height: 40),
        _buildWelcomeMessage(context),
        const SizedBox(height: 40),
        const WelcomeActionButtons(),
        const SizedBox(height: 24),
        const LoginPromptButton(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left side (branding)
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBranding(
                logoSize: 160,
                alignment: Alignment.centerLeft,
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 40),
              _buildWelcomeMessage(context, alignment: TextAlign.left),
            ],
          ),
        ),
        const SizedBox(width: 60),
        // Right side (actions)
        Expanded(
          flex: 4,
          child: Card(
            color: Colors.grey.shade900.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Get Started',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const WelcomeActionButtons(),
                  const SizedBox(height: 32),
                  const LoginPromptButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}