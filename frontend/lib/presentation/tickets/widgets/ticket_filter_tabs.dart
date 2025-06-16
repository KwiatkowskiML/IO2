import 'package:flutter/material.dart';

class TicketFilterTabs extends StatelessWidget {
  final TabController tabController;
  final VoidCallback onTabChange;

  const TicketFilterTabs({
    super.key,
    required this.tabController,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: TabBar(
          controller: tabController,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicator: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.normal,
          ),
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: [
            _CustomTab(
              icon: Icons.confirmation_number_outlined,
              selectedIcon: Icons.confirmation_number,
              text: 'All Tickets',
            ),
            _CustomTab(
              icon: Icons.event_available_outlined,
              selectedIcon: Icons.event_available,
              text: 'Upcoming',
            ),
            _CustomTab(
              icon: Icons.sell_outlined,
              selectedIcon: Icons.sell,
              text: 'On Resale',
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomTab extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String text;

  const _CustomTab({
    required this.icon,
    required this.selectedIcon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The TabBar will handle the icon color based on selection state
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}