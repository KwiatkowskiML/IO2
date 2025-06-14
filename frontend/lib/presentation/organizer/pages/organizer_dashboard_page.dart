import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/organizer/cubit/organizer_dashboard_cubit.dart';
import 'package:resellio/presentation/organizer/cubit/organizer_dashboard_state.dart';

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
            return BlocStateWrapper<OrganizerDashboardLoaded>(
              state: state,
              onRetry: () =>
                  context.read<OrganizerDashboardCubit>().loadDashboard(),
              builder: (loadedState) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _WelcomeCard(),
                    const SizedBox(height: 24),
                    _StatCardGrid(events: loadedState.events),
                    const SizedBox(height: 24),
                    _QuickActions(),
                    const SizedBox(height: 24),
                    _RecentEventsList(events: loadedState.events),
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

class _WelcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${user?.name ?? 'Organizer'}!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Here\'s an overview of your events and activities.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCardGrid extends StatelessWidget {
  final List<Event> events;

  const _StatCardGrid({required this.events});

  @override
  Widget build(BuildContext context) {
    final activeEvents = events.where((e) => e.status == 'created').length;
    final pendingEvents = events.where((e) => e.status == 'pending').length;
    final totalTickets = events.fold(0, (sum, e) => sum + e.totalTickets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
                title: 'Total Events',
                value: events.length.toString(),
                icon: Icons.event,
                color: Colors.blue),
            _StatCard(
                title: 'Active Events',
                value: activeEvents.toString(),
                icon: Icons.event_available,
                color: Colors.green),
            _StatCard(
                title: 'Pending Events',
                value: pendingEvents.toString(),
                icon: Icons.pending,
                color: Colors.orange),
            _StatCard(
                title: 'Total Tickets',
                value: totalTickets.toString(),
                icon: Icons.confirmation_number,
                color: Colors.purple),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ActionCard(
                title: 'Create Event',
                icon: Icons.add_circle_outline,
                color: Colors.green,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Create Event page - Coming Soon!')),
                  );
                },
              ),
              _ActionCard(
                title: 'View Analytics',
                icon: Icons.bar_chart,
                color: Colors.blue,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Statistics page - Coming Soon!')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard(
      {required this.title,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentEventsList extends StatelessWidget {
  final List<Event> events;

  const _RecentEventsList({required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Events',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (events.isEmpty)
          const _EmptyState(
            icon: Icons.event_note,
            message: 'No events yet',
            details: 'Create your first event to get started.',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.take(3).length,
            itemBuilder: (context, index) =>
                _EventListItem(event: events[index]),
          ),
      ],
    );
  }
}

class _EventListItem extends StatelessWidget {
  final Event event;

  const _EventListItem({required this.event});

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(context, event.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(DateFormat.yMMMd().format(event.start),
                          style: theme.textTheme.bodySmall),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
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
                style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String details;

  const _EmptyState(
      {required this.icon, required this.message, required this.details});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Icon(icon,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(message, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                details,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
