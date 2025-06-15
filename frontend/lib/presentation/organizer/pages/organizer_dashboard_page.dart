import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/common_widgets/empty_state_widget.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/organizer/cubit/organizer_dashboard_cubit.dart';
import 'package:resellio/presentation/organizer/cubit/organizer_dashboard_state.dart';
import 'package:resellio/presentation/organizer/widgets/quick_actions.dart';
import 'package:resellio/presentation/organizer/widgets/recent_events_list.dart';
import 'package:resellio/presentation/organizer/widgets/stat_card_grid.dart';
import 'package:resellio/presentation/organizer/widgets/welcome_card.dart';

class OrganizerDashboardPage extends StatelessWidget {
  const OrganizerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrganizerDashboardCubit(
        context.read<EventRepository>(),
        context.read<AuthService>(),
      )..loadDashboard(),
      child: const _OrganizerDashboardView(),
    );
  }
}

class _OrganizerDashboardView extends StatelessWidget {
  const _OrganizerDashboardView();

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Dashboard',
      showCartButton: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Data',
          onPressed: () =>
              context.read<OrganizerDashboardCubit>().loadDashboard(),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<OrganizerDashboardCubit>().loadDashboard(),
        child: BlocBuilder<OrganizerDashboardCubit, OrganizerDashboardState>(
          builder: (context, state) {
            if (state is OrganizerDashboardUnverified) {
              return EmptyStateWidget(
                  icon: Icons.verified_user_outlined,
                  message: 'Verification Pending',
                  details: state.message);
            }
            return BlocStateWrapper<OrganizerDashboardLoaded>(
              state: state,
              onRetry: () =>
                  context.read<OrganizerDashboardCubit>().loadDashboard(),
              builder: (loadedState) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const WelcomeCard(),
                    const SizedBox(height: 24),
                    StatCardGrid(events: loadedState.events),
                    const SizedBox(height: 24),
                    const QuickActions(),
                    const SizedBox(height: 24),
                    RecentEventsList(events: loadedState.events),
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
