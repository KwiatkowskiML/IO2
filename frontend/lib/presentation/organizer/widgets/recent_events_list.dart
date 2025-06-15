import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/presentation/common_widgets/dialogs.dart';
import 'package:resellio/presentation/common_widgets/empty_state_widget.dart';
import 'package:resellio/presentation/organizer/cubit/organizer_dashboard_cubit.dart';

class RecentEventsList extends StatelessWidget {
  final List<Event> events;

  const RecentEventsList({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Events',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (events.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: EmptyStateWidget(
                icon: Icons.event_note,
                message: 'No events yet',
                details: 'Create your first event to get started.',
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.take(3).length,
            itemBuilder: (context, index) =>
                _EventListItem(event: events[index]),
          ),
      ],
    );
  }
}

class _EventListItem extends StatelessWidget {
  final Event event;

  const _EventListItem({required this.event});

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

  void _showCancelDialog(BuildContext context, Event event) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Cancel Event?',
      content: Text('Are you sure you want to cancel "${event.name}"?'),
      confirmText: 'Yes, Cancel',
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<OrganizerDashboardCubit>().cancelEvent(event.id);
    }
  }

  void _showNotifyDialog(BuildContext context, Event event) async {
    final message = await showInputDialog(
      context: context,
      title: 'Notify Participants',
      label: 'Message',
      confirmText: 'Send',
    );
    if (message != null && message.isNotEmpty && context.mounted) {
      context.read<OrganizerDashboardCubit>().notifyParticipants(event.id, message);
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
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 8),
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
                  context.push('/organizer/edit-event/${event.id}', extra: event);
                } else if (value == 'notify') {
                  _showNotifyDialog(context, event);
                } else if (value == 'cancel') {
                  _showCancelDialog(context, event);
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
