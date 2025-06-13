import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double verticalPadding;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double? width;
  final double borderRadius;
  final double elevation;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.verticalPadding = 16,
    this.isLoading = false,
    this.icon,
    this.height = 52,
    this.width,
    this.borderRadius = 16,
    this.elevation = 0,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buttonChild;

    if (isLoading) {
      buttonChild = SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: foregroundColor ?? colorScheme.onPrimary,
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
              color: foregroundColor ?? colorScheme.onPrimary,
            ),
          ),
        ],
      );
    } else {
      buttonChild = Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
          color: foregroundColor ?? colorScheme.onPrimary,
        ),
      );
    }

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return (backgroundColor ?? colorScheme.primary).withOpacity(0.6);
          }
          return backgroundColor ?? colorScheme.primary;
        }),
        foregroundColor: WidgetStateProperty.all<Color>(
          foregroundColor ?? colorScheme.onPrimary,
        ),
        elevation: WidgetStateProperty.all<double>(elevation),
        padding: WidgetStateProperty.all<EdgeInsets>(
          EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 24),
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.onPrimary.withOpacity(0.1);
          }
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.onPrimary.withOpacity(0.05);
          }
          return null;
        }),
        fixedSize: WidgetStateProperty.all<Size?>(
          Size(width ?? double.infinity, height),
        ),
        animationDuration: const Duration(milliseconds: 200),
      ),
      child: Center(child: buttonChild),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
