import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_cubit.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_state.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
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
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                          'Pending Organizers: ${loadedState.pendingOrganizers.length}'),
                      Text('Total Users: ${loadedState.allUsers.length}'),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
