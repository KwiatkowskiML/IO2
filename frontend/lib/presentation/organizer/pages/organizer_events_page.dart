import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/common_widgets/dialogs.dart';
import 'package:resellio/presentation/common_widgets/empty_state_widget.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/organizer/cubit/my_events_cubit.dart';
import 'package:resellio/presentation/organizer/cubit/my_events_state.dart';
import 'package:resellio/presentation/organizer/widgets/event_list_filter_chips.dart';

class OrganizerEventsPage extends StatelessWidget {
  const OrganizerEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MyEventsCubit(
        context.read<EventRepository>(),
        context.read<AuthService>(),
      )..loadEvents(),
      child: const _OrganizerEventsView(),
    );
  }
}

class _OrganizerEventsView extends StatelessWidget {
  const _OrganizerEventsView();

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'My Events',
      showCartButton: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Events',
          onPressed: () => context.read<MyEventsCubit>().loadEvents(),
        ),
      ],
      body: Column(
        children: [
          BlocBuilder<MyEventsCubit, MyEventsState>(
            builder: (context, state) {
              if (state is MyEventsLoaded) {
                return EventListFilterChips(
                  selectedFilter: state.activeFilter,
                  onFilterChanged: (filter) {
                    context.read<MyEventsCubit>().setFilter(filter);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child:
                BlocConsumer<MyEventsCubit, MyEventsState>(
              listener: (context, state) {
                if (state is MyEventsError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: ${state.message}'),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              builder: (context, state) {
                return BlocStateWrapper<MyEventsLoaded>(
                  state: state,
                  onRetry: () => context.read<MyEventsCubit>().loadEvents(),
                  builder: (loadedState) {
                    final events = loadedState.filteredEvents;

                    if (events.isEmpty) {
                      return const EmptyStateWidget(
                        icon: Icons.event_note,
                        message: 'No events match this filter',
                        details: 'Try selecting a different filter or create a new event.',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => context.read<MyEventsCubit>().loadEvents(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          return _EventListItem(event: events[index]);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class _EventListItem extends StatelessWidget {
  final Event event;

  const _EventListItem({required this.event});

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'created': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Theme.of(context).colorScheme.onSurfaceVariant;
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
      context.read<MyEventsCubit>().cancelEvent(event.id);
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
      context.read<MyEventsCubit>().notifyParticipants(event.id, message);
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
                      Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(DateFormat.yMMMd().format(event.start), style: theme.textTheme.bodySmall),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on, size: 14, color: theme.colorScheme.onSurfaceVariant),
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
                  child: Text('Cancel Event', style: TextStyle(color: theme.colorScheme.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
