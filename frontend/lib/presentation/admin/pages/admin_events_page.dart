import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_cubit.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_state.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/common_widgets/list_item_card.dart';
import 'package:resellio/presentation/common_widgets/dialogs.dart';
import 'package:resellio/presentation/common_widgets/empty_state_widget.dart';

class AdminEventsPage extends StatelessWidget {
  const AdminEventsPage({super.key});

  void _showEventDetails(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => _EventDetailsDialog(event: event),
    );
  }

  void _showAuthorizationConfirmation(
      BuildContext context,
      Event event,
      bool approve,
      ) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: approve ? 'Authorize Event' : 'Reject Event',
      content: Text(
        approve
            ? 'Are you sure you want to authorize "${event.name}"?\n\n'
            'This will make the event visible to customers and allow ticket sales.'
            : 'Are you sure you want to reject "${event.name}"?\n\n'
            'This will prevent the event from being published.',
      ),
      confirmText: approve ? 'Authorize' : 'Reject',
      isDestructive: !approve,
    );

    if (confirmed == true && context.mounted) {
      try {
        if (approve) {
          await context.read<AdminDashboardCubit>().authorizeEvent(event.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event "${event.name}" has been authorized'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          await context.read<AdminDashboardCubit>().rejectEvent(event.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event "${event.name}" has been rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        return BlocStateWrapper<AdminDashboardLoaded>(
          state: state,
          onRetry: () => context.read<AdminDashboardCubit>().loadDashboard(),
          builder: (loadedState) {
            if (loadedState.pendingEvents.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.event_outlined,
                message: 'No pending events',
                details: 'All events have been reviewed and processed.',
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event_note,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pending Event Authorizations',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${loadedState.pendingEvents.length} event(s) awaiting authorization',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Events List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: loadedState.pendingEvents.length,
                    itemBuilder: (context, index) {
                      final event = loadedState.pendingEvents[index];
                      final isProcessing = state is EventAuthorizationInProgress &&
                          state.eventId == event.id;

                      return _PendingEventCard(
                        event: event,
                        isProcessing: isProcessing,
                        onViewDetails: () => _showEventDetails(context, event),
                        onAuthorize: () =>
                            _showAuthorizationConfirmation(context, event, true),
                        onReject: () =>
                            _showAuthorizationConfirmation(context, event, false),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PendingEventCard extends StatelessWidget {
  final Event event;
  final bool isProcessing;
  final VoidCallback onViewDetails;
  final VoidCallback onAuthorize;
  final VoidCallback onReject;

  const _PendingEventCard({
    required this.event,
    required this.isProcessing,
    required this.onViewDetails,
    required this.onAuthorize,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');

    return ListItemCard(
      isProcessing: isProcessing,
      leadingWidget: Container(
        width: 60,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: [
            Text(
              DateFormat('MMM').format(event.start),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              DateFormat('d').format(event.start),
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      title: Text(event.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${timeFormat.format(event.start)} - ${timeFormat.format(event.end)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.location,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PENDING AUTHORIZATION',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (event.category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.category.first,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      bottomContent: Column(
        children: [
          // Event Stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildStatItem(
                  context,
                  Icons.confirmation_number,
                  '${event.totalTickets} tickets',
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  context,
                  Icons.business,
                  'Organizer ID: ${event.organizerId}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Action Buttons
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: isProcessing ? null : onViewDetails,
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('View Details'),
              ),
              TextButton.icon(
                onPressed: isProcessing ? null : onReject,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Reject'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
              ElevatedButton.icon(
                onPressed: isProcessing ? null : onAuthorize,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Authorize'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EventDetailsDialog extends StatelessWidget {
  final Event event;

  const _EventDetailsDialog({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final DateFormat dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.event,
              color: colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  'Event Details',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 120,
                      maxWidth: double.infinity,
                    ),
                    child: Image.network(
                      event.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_not_supported,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildSection(
                context,
                'Event Information',
                [
                  _buildDetailRow('Event Name', event.name),
                  _buildDetailRow('Description', event.description ?? 'No description'),
                  _buildDetailRow('Status', event.status.toUpperCase()),
                  _buildDetailRow('Event ID', event.id.toString()),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Date & Time',
                [
                  _buildDetailRow('Date', dateFormat.format(event.start)),
                  _buildDetailRow(
                    'Time',
                    '${timeFormat.format(event.start)} - ${timeFormat.format(event.end)}',
                  ),
                  _buildDetailRow('Location', event.location),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Event Details',
                [
                  _buildDetailRow('Organizer ID', event.organizerId.toString()),
                  _buildDetailRow('Total Tickets', event.totalTickets.toString()),
                  if (event.minimumAge != null)
                    _buildDetailRow('Minimum Age', '${event.minimumAge} years'),
                  if (event.category.isNotEmpty)
                    _buildDetailRow('Categories', event.category.join(', ')),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This event requires authorization before it can be published and made available for ticket sales.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Trigger reject action from parent context
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Trigger authorize action from parent context
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Authorize'),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}