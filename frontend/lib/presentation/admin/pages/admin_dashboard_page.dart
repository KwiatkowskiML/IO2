// Enhanced admin_dashboard_page.dart with better logout functionality

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/core/utils/responsive_layout.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_cubit.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_state.dart';
import 'package:resellio/presentation/admin/pages/admin_users_page.dart';
import 'package:resellio/presentation/admin/pages/admin_organizers_page.dart';
import 'package:resellio/presentation/admin/pages/admin_events_page.dart';
import 'package:resellio/presentation/admin/pages/admin_registration_page.dart';
import 'package:resellio/presentation/admin/pages/admin_overview_page.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/admin/pages/admin_verification_page.dart';
import 'package:resellio/presentation/common_widgets/dialogs.dart';

class AdminMainPage extends StatefulWidget {
  final String? initialTab;

  const AdminMainPage({super.key, this.initialTab});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  late String _selectedTab;

  final List<AdminTab> _tabs = [
    AdminTab(
      id: 'overview',
      title: 'Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: '/admin',
    ),
    AdminTab(
      id: 'users',
      title: 'Users',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      route: '/admin/users',
    ),
    AdminTab(
      id: 'organizers',
      title: 'Organizers',
      icon: Icons.verified_user_outlined,
      selectedIcon: Icons.verified_user,
      route: '/admin/organizers',
    ),
    AdminTab(
      id: 'verification',
      title: 'Verification',
      icon: Icons.mark_email_read_outlined,
      selectedIcon: Icons.mark_email_read,
      route: '/admin/verification',
    ),
    AdminTab(
      id: 'events',
      title: 'Events',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
      route: '/admin/events',
    ),
    AdminTab(
      id: 'add-admin',
      title: 'Add Admin',
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings,
      route: '/admin/add-admin',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab ?? 'overview';
  }

  void _onTabChanged(String tabId) {
    setState(() {
      _selectedTab = tabId;
    });

    final tab = _tabs.firstWhere((t) => t.id == tabId);
    if (context.mounted) {
      context.go(tab.route);
    }
  }

  // Enhanced logout function with confirmation
  void _showLogoutDialog() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Logout',
      content: const Text('Are you sure you want to logout from the admin panel?'),
      confirmText: 'Logout',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<AuthService>().logout();
        // Navigation will be handled automatically by the router
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _getSelectedPage() {
    switch (_selectedTab) {
      case 'overview':
        return const AdminOverviewPage();
      case 'users':
        return const AdminUsersPage();
      case 'organizers':
        return const AdminOrganizersPage();
      case 'verification':
        return const AdminVerificationPage();
      case 'events':
        return const AdminEventsPage();
      case 'add-admin':
        return const AdminRegistrationPage();
      default:
        return const AdminOverviewPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminDashboardCubit(
        context.read<AdminRepository>(),
      )..loadDashboard(),
      child: _AdminMainView(
        tabs: _tabs,
        selectedTab: _selectedTab,
        onTabChanged: _onTabChanged,
        onLogout: _showLogoutDialog,
        body: _getSelectedPage(),
      ),
    );
  }
}

class _AdminMainView extends StatelessWidget {
  final List<AdminTab> tabs;
  final String selectedTab;
  final Function(String) onTabChanged;
  final VoidCallback onLogout;
  final Widget body;

  const _AdminMainView({
    required this.tabs,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onLogout,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);
    final authService = context.watch<AuthService>();

    return PageLayout(
      title: 'Admin Panel',
      showCartButton: false,
      actions: [
        // Admin info and logout in the top bar
        if (!isMobile) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 16,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  authService.user?.name ?? 'Admin',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
          builder: (context, state) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
              onPressed: state is AdminDashboardLoading
                  ? null
                  : () => context.read<AdminDashboardCubit>().loadDashboard(),
            );
          },
        ),
        // Logout button in top bar
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: onLogout,
        ),
      ],
      body: isMobile
          ? Column(
        children: [
          _buildMobileTabBar(theme, colorScheme),
          // Mobile admin info bar
          Container(
            width: double.infinity,
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Admin: ${authService.user?.name ?? 'Unknown'}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onLogout,
                  icon: Icon(Icons.logout, size: 16),
                  label: Text('Logout'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      )
          : Row(
        children: [
          _buildSidebar(theme, colorScheme, authService),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildMobileTabBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isSelected = tab.id == selectedTab;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? tab.selectedIcon : tab.icon,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(tab.title),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => onTabChanged(tab.id),
                backgroundColor: colorScheme.surfaceContainerHighest,
                selectedColor: colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme, ColorScheme colorScheme, AuthService authService) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with admin info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Panel',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'System Management',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Admin user info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.secondary,
                        child: Icon(
                          Icons.person,
                          color: colorScheme.onSecondary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authService.user?.name ?? 'Admin User',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Administrator',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: tabs.map((tab) {
                final isSelected = tab.id == selectedTab;
                return _SidebarItem(
                  tab: tab,
                  isSelected: isSelected,
                  onTap: () => onTabChanged(tab.id),
                  theme: theme,
                  colorScheme: colorScheme,
                );
              }).toList(),
            ),
          ),

          // Enhanced logout section
          Container(
            margin: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Statistics Summary (existing)
                BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
                  builder: (context, state) {
                    if (state is AdminDashboardLoaded) {
                      return _buildStatsSummary(state, theme, colorScheme);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 12),
                // Prominent logout button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(
      AdminDashboardLoaded state,
      ThemeData theme,
      ColorScheme colorScheme,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _StatRow(
            icon: Icons.people,
            label: 'Total Users',
            value: state.allUsers.length.toString(),
            color: Colors.blue,
          ),
          _StatRow(
            icon: Icons.pending_actions,
            label: 'Pending Organizers',
            value: state.pendingOrganizers.length.toString(),
            color: Colors.orange,
          ),
          _StatRow(
            icon: Icons.mark_email_read,
            label: 'Unverified Users',
            value: state.unverifiedUsers.length.toString(),
            color: Colors.purple,
          ),
          _StatRow(
            icon: Icons.event_note,
            label: 'Pending Events',
            value: state.pendingEvents.length.toString(),
            color: Colors.purple,
          ),
          _StatRow(
            icon: Icons.block,
            label: 'Banned Users',
            value: state.bannedUsers.length.toString(),
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final AdminTab tab;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _SidebarItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? tab.selectedIcon : tab.icon,
                  size: 20,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  tab.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminTab {
  final String id;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  AdminTab({
    required this.id,
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}