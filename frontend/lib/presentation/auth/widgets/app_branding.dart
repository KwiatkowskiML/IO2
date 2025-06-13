import 'package:flutter/material.dart';

class AppBranding extends StatelessWidget {
  final double logoSize;
  final Alignment alignment;
  final TextAlign textAlign;
  final bool showTitle;
  final bool showTagline;

  const AppBranding({
    super.key,
    this.logoSize = 120,
    this.alignment = Alignment.center,
    this.textAlign = TextAlign.center,
    this.showTitle = true,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignment == Alignment.centerLeft
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
      children: [
        _buildLogo(context, size: logoSize),
        if (showTitle) const SizedBox(height: 32),
        if (showTitle) _buildAppTitle(context, alignment: alignment),
        if (showTitle && showTagline) const SizedBox(height: 16),
        if (showTagline) _buildTagline(context, alignment: textAlign),
      ],
    );
  }

  Widget _buildLogo(BuildContext context, {double size = 120}) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.confirmation_number_outlined,
        size: size / 2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildAppTitle(
    BuildContext context, {
    Alignment alignment = Alignment.center,
  }) {
    return Align(
      alignment: alignment,
      child: Text(
        'RESELLIO',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTagline(
    BuildContext context, {
    TextAlign alignment = TextAlign.center,
  }) {
    return Text(
      'The Ticket Marketplace',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.white70,
        letterSpacing: 0.5,
      ),
      textAlign: alignment,
    );
  }
}
