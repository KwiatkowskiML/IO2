import 'package:flutter/material.dart';

import 'admin_info_row.dart';

class AdminStatsContainer extends StatelessWidget {
  final List<AdminStatItem> stats;

  const AdminStatsContainer({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: stats.map((stat) => AdminInfoRow(
          icon: stat.icon,
          text: stat.text,
          iconColor: stat.color,
        )).toList(),
      ),
    );
  }
}

class AdminStatItem {
  final IconData icon;
  final String text;
  final Color? color;

  AdminStatItem({
    required this.icon,
    required this.text,
    this.color,
  });
}