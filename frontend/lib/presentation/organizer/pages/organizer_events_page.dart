import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/common_widgets/empty_state_widget.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/organizer/cubit/my_events_cubit.dart';
import 'package:resellio/presentation/organizer/cubit/my_events_state.dart';
import 'package:resellio/presentation/organizer/widgets/event_list_filter_chips.dart';
import 'package:resellio/presentation/organizer/widgets/organizer_event_list_item.dart';

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
            child: BlocConsumer<MyEventsCubit, MyEventsState>(
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
                        details:
                            'Try selecting a different filter or create a new event.',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          context.read<MyEventsCubit>().loadEvents(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return OrganizerEventListItem(
                            event: event,
                            onCancel: () => context
                                .read<MyEventsCubit>()
                                .cancelEvent(event.id),
                            onNotify: (message) => context
                                .read<MyEventsCubit>()
                                .notifyParticipants(event.id, message),
                          );
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
