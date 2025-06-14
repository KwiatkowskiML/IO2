import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_cubit.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_state.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
            if (state is AdminDashboardLoading || state is AdminDashboardInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AdminDashboardError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Failed to load dashboard',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: colorScheme.error)),
                    const SizedBox(height: 8),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<AdminDashboardCubit>().loadDashboard(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state is AdminDashboardLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                        'Pending Organizers: ${state.pendingOrganizers.length}'),
                    Text('Total Users: ${state.allUsers.length}'),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
