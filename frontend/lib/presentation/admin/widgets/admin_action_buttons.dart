import 'package:flutter/material.dart';

class AdminActionButtons extends StatelessWidget {
  final List<AdminAction> actions;
  final bool isProcessing;

  const AdminActionButtons({
    super.key,
    required this.actions,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return OverflowBar(
      alignment: MainAxisAlignment.end,
      children: actions.map((action) {
        if (action.isPrimary) {
          return ElevatedButton.icon(
            onPressed: isProcessing ? null : action.onPressed,
            icon: Icon(action.icon, size: 18),
            label: Text(action.label),
            style: ElevatedButton.styleFrom(
              backgroundColor: action.color,
              foregroundColor: action.textColor ?? Colors.white,
            ),
          );
        } else {
          return TextButton.icon(
            onPressed: isProcessing ? null : action.onPressed,
            icon: Icon(action.icon, size: 18),
            label: Text(action.label),
            style: TextButton.styleFrom(
              foregroundColor: action.color,
            ),
          );
        }
      }).toList(),
    );
  }
}

class AdminAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final bool isPrimary;

  const AdminAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
    this.textColor,
    this.isPrimary = false,
  });

  factory AdminAction.primary({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return AdminAction(
      label: label,
      icon: icon,
      onPressed: onPressed,
      color: color ?? Colors.green,
      isPrimary: true,
    );
  }

  factory AdminAction.secondary({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return AdminAction(
      label: label,
      icon: icon,
      onPressed: onPressed,
      color: color,
      isPrimary: false,
    );
  }

  factory AdminAction.destructive({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return AdminAction(
      label: label,
      icon: icon,
      onPressed: onPressed,
      color: Colors.red,
      isPrimary: false,
    );
  }
}