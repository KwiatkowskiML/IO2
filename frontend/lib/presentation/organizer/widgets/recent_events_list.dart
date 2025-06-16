import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/presentation/common_widgets/empty_state_widget.dart';
import 'package:resellio/presentation/organizer/cubit/organizer_dashboard_cubit.dart';
import 'package:resellio/presentation/organizer/widgets/organizer_event_list_item.dart';

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
            itemBuilder: (context, index) {
              final event = events[index];
              return OrganizerEventListItem(
                event: event,
                onCancel: () => context
                    .read<OrganizerDashboardCubit>()
                    .cancelEvent(event.id),
                onNotify: (message) => context
                    .read<OrganizerDashboardCubit>()
                    .notifyParticipants(event.id, message),
              );
            },
          ),
      ],
    );
  }
}
