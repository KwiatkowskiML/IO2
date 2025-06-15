import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/organizer/cubit/organizer_stats_cubit.dart';
import 'package:resellio/presentation/organizer/cubit/organizer_stats_state.dart';
import 'package:resellio/presentation/organizer/widgets/stats_summary_card.dart';

class OrganizerStatsPage extends StatelessWidget {
  const OrganizerStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrganizerStatsCubit(
        context.read<EventRepository>(),
        context.read<AuthService>(),
      )..loadStatistics(),
      child: const _OrganizerStatsView(),
    );
  }
}

class _OrganizerStatsView extends StatelessWidget {
  const _OrganizerStatsView();

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Statistics',
      showCartButton: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Statistics',
          onPressed: () => context.read<OrganizerStatsCubit>().loadStatistics(),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () => context.read<OrganizerStatsCubit>().loadStatistics(),
        child: BlocBuilder<OrganizerStatsCubit, OrganizerStatsState>(
          builder: (context, state) {
            return BlocStateWrapper<OrganizerStatsLoaded>(
              state: state,
              onRetry: () =>
                  context.read<OrganizerStatsCubit>().loadStatistics(),
              builder: (loadedState) {
                return GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    StatsSummaryCard(
                      title: 'Total Events',
                      value: loadedState.totalEvents.toString(),
                      icon: Icons.event,
                      color: Colors.blue,
                    ),
                    StatsSummaryCard(
                      title: 'Active Events',
                      value: loadedState.activeEvents.toString(),
                      icon: Icons.event_available,
                      color: Colors.green,
                    ),
                    StatsSummaryCard(
                      title: 'Pending Approval',
                      value: loadedState.pendingEvents.toString(),
                      icon: Icons.pending,
                      color: Colors.orange,
                    ),
                    StatsSummaryCard(
                      title: 'Total Tickets',
                      value: loadedState.totalTickets.toString(),
                      icon: Icons.confirmation_number,
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
