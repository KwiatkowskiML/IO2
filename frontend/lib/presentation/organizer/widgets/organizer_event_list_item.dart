import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/presentation/common_widgets/dialogs.dart';

class OrganizerEventListItem extends StatelessWidget {
  final Event event;
  final VoidCallback onCancel;
  final Function(String) onNotify;

  const OrganizerEventListItem({
    super.key,
    required this.event,
    required this.onCancel,
    required this.onNotify,
  });

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  void _showCancelDialog(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Cancel Event?',
      content: Text('Are you sure you want to cancel "${event.name}"?'),
      confirmText: 'Yes, Cancel',
      isDestructive: true,
    );
    if (confirmed == true) {
      onCancel();
    }
  }

  void _showNotifyDialog(BuildContext context) async {
    final message = await showInputDialog(
      context: context,
      title: 'Notify Participants',
      label: 'Message',
      confirmText: 'Send',
    );
    if (message != null && message.isNotEmpty) {
      onNotify(message);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(context, event.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding:
            const EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(DateFormat.yMMMd().format(event.start),
                          style: theme.textTheme.bodySmall),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(event.location, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                event.status.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(color: statusColor),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  context.push('/organizer/edit-event/${event.id}',
                      extra: event);
                } else if (value == 'notify') {
                  _showNotifyDialog(context);
                } else if (value == 'cancel') {
                  _showCancelDialog(context);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit Event'),
                ),
                const PopupMenuItem<String>(
                  value: 'notify',
                  child: Text('Notify Participants'),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'cancel',
                  child: Text('Cancel Event',
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
