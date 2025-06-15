import 'package:flutter/material.dart';
import 'package:resellio/core/models/models.dart';

class StatCardGrid extends StatelessWidget {
  final List<Event> events;

  const StatCardGrid({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final activeEvents = events.where((e) => e.status == 'created').length;
    final pendingEvents = events.where((e) => e.status == 'pending').length;
    final totalTickets = events.fold(0, (sum, e) => sum + e.totalTickets);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.2,
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: theme.textTheme.headlineSmall?.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(title, style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
