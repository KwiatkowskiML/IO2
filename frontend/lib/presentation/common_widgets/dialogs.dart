import 'package:flutter/material.dart';
import 'package:resellio/presentation/common_widgets/primary_button.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  String confirmText = 'Confirm',
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        PrimaryButton(
          text: confirmText,
          onPressed: () => Navigator.of(context).pop(true),
          backgroundColor:
              isDestructive ? Theme.of(context).colorScheme.error : null,
          fullWidth: false,
        ),
      ],
    ),
  );
}

Future<String?> showInputDialog({
  required BuildContext context,
  required String title,
  required String label,
  String confirmText = 'Submit',
  String? initialValue,
  TextInputType keyboardType = TextInputType.text,
  String? prefixText,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            prefixText: prefixText,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            text: confirmText,
            onPressed: () => Navigator.of(context).pop(controller.text),
            fullWidth: false,
          ),
        ],
      );
    },
  );
}
