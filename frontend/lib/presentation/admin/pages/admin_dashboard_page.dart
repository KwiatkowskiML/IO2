import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/admin_model.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_cubit.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_state.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/common_widgets/list_item_card.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AdminDashboardCubit(context.read<AdminRepository>())..loadDashboard(),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Admin Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<AdminDashboardCubit>().loadDashboard(),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminDashboardCubit>().loadDashboard(),
        child: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
          builder: (context, state) {
            return BlocStateWrapper<AdminDashboardLoaded>(
              state: state,
              onRetry: () =>
                  context.read<AdminDashboardCubit>().loadDashboard(),
              builder: (loadedState) {
                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Text('Pending Organizers',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (loadedState.pendingOrganizers.isEmpty)
                      const Text('No organizers pending verification.')
                    else
                      ...loadedState.pendingOrganizers
                          .map((org) => _PendingOrganizerCard(organizer: org)),
                    const SizedBox(height: 24),
                    Text('All Users',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ...loadedState.allUsers
                        .map((user) => _UserCard(user: user)),
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

class _PendingOrganizerCard extends StatelessWidget {
  final PendingOrganizer organizer;
  const _PendingOrganizerCard({required this.organizer});

  @override
  Widget build(BuildContext context) {
    return ListItemCard(
      title: Text(organizer.companyName),
      subtitle: Text(organizer.email),
      bottomContent: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: OverflowBar(
          alignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => context
                  .read<AdminDashboardCubit>()
                  .verifyOrganizer(organizer.organizerId, false),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Reject'),
            ),
            TextButton(
              onPressed: () => context
                  .read<AdminDashboardCubit>()
                  .verifyOrganizer(organizer.organizerId, true),
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserDetails user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListItemCard(
      title: Text('${user.firstName} ${user.lastName}'),
      subtitle: Text(user.email),
      trailingWidget: Chip(
        label: Text(user.userType),
        backgroundColor:
            user.isActive ? Colors.green.withOpacity(0.2) : Colors.grey,
      ),
    );
  }
}
