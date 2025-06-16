import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_cubit.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_state.dart';
import 'package:resellio/presentation/admin/widgets/admin_card.dart';
import 'package:resellio/presentation/admin/widgets/admin_section_header.dart';
import 'package:resellio/presentation/admin/widgets/admin_action_buttons.dart';
import 'package:resellio/presentation/admin/widgets/admin_status_chip.dart';
import 'package:resellio/presentation/admin/widgets/admin_info_row.dart';
import 'package:resellio/presentation/admin/widgets/admin_detail_dialog.dart';
import 'package:resellio/presentation/admin/widgets/admin_stats_container.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/common_widgets/dialogs.dart';
import 'package:resellio/presentation/common_widgets/empty_state_widget.dart';
import 'package:resellio/presentation/common_widgets/list_item_card.dart';

class AdminEventsPage extends StatelessWidget {
  const AdminEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
              children: [
                AdminCard(
                  header: AdminSectionHeader(
                    icon: Icons.event_note,
                    title: 'Pending Event Authorizations',
                    subtitle: '${loadedState.pendingEvents.length} event(s) awaiting authorization',
                  ),
                  child: const SizedBox.shrink(),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: loadedState.pendingEvents.length,
                    itemBuilder: (context, index) {
                      final event = loadedState.pendingEvents[index];
                      final isProcessing = state is EventAuthorizationInProgress &&
                          state.eventId == event.id;

                      return _EventCard(
                        event: event,
                        isProcessing: isProcessing,
                        onViewDetails: () => _showEventDetails(context, event),
                        onAuthorize: () => _showAuthorizationConfirmation(context, event, true),
                        onReject: () => _showAuthorizationConfirmation(context, event, false),
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

  void _showEventDetails(BuildContext context, Event event) {
    final DateFormat dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');

    showDialog(
      context: context,
      builder: (context) => AdminDetailDialog(
        icon: Icons.event,
        title: event.name,
        subtitle: 'Event Details',
        sections: [
          AdminDetailSection(
            title: 'Event Information',
            rows: [
              AdminDetailRow(label: 'Event Name', value: event.name),
              AdminDetailRow(label: 'Description', value: event.description ?? 'No description'),
              AdminDetailRow(label: 'Status', value: event.status.toUpperCase()),
              AdminDetailRow(label: 'Event ID', value: event.id.toString()),
            ],
          ),
          AdminDetailSection(
            title: 'Date & Time',
            rows: [
              AdminDetailRow(label: 'Date', value: dateFormat.format(event.start)),
              AdminDetailRow(
                label: 'Time',
                value: '${timeFormat.format(event.start)} - ${timeFormat.format(event.end)}',
              ),
              AdminDetailRow(label: 'Location', value: event.location),
            ],
          ),
          AdminDetailSection(
            title: 'Event Details',
            rows: [
              AdminDetailRow(label: 'Organizer ID', value: event.organizerId.toString()),
              AdminDetailRow(label: 'Total Tickets', value: event.totalTickets.toString()),
              if (event.minimumAge != null)
                AdminDetailRow(label: 'Minimum Age', value: '${event.minimumAge} years'),
              if (event.category.isNotEmpty)
                AdminDetailRow(label: 'Categories', value: event.category.join(', ')),
            ],
          ),
        ],
        footer: _buildWarningFooter(),
      ),
    );
  }

  Widget _buildWarningFooter() {
    return Container(
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
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
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
}

class _EventCard extends StatelessWidget {
  final Event event;
  final bool isProcessing;
  final VoidCallback onViewDetails;
  final VoidCallback onAuthorize;
  final VoidCallback onReject;

  const _EventCard({
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
          AdminInfoRow(
            icon: Icons.access_time,
            text: '${timeFormat.format(event.start)} - ${timeFormat.format(event.end)}',
          ),
          const SizedBox(height: 2),
          AdminInfoRow(
            icon: Icons.location_on,
            text: event.location,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const AdminStatusChip(type: AdminStatusType.pending, customText: 'PENDING AUTHORIZATION'),
              const SizedBox(width: 8),
              if (event.category.isNotEmpty)
                AdminStatusChip(
                  type: AdminStatusType.waiting,
                  customText: event.category.first.toUpperCase(),
                ),
            ],
          ),
        ],
      ),
      bottomContent: Column(
        children: [
          AdminStatsContainer(
            stats: [
              AdminStatItem(
                icon: Icons.confirmation_number,
                text: '${event.totalTickets} tickets',
              ),
              AdminStatItem(
                icon: Icons.business,
                text: 'Organizer ID: ${event.organizerId}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdminActionButtons(
            isProcessing: isProcessing,
            actions: [
              AdminAction.secondary(
                label: 'View Details',
                icon: Icons.info_outline,
                onPressed: onViewDetails,
              ),
              AdminAction.destructive(
                label: 'Reject',
                icon: Icons.close,
                onPressed: onReject,
              ),
              AdminAction.primary(
                label: 'Authorize',
                icon: Icons.check,
                onPressed: onAuthorize,
              ),
            ],
          ),
        ],
      ),
    );
  }
}