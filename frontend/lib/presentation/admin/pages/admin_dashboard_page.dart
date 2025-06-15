import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/utils/responsive_layout.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_cubit.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_state.dart';
import 'package:resellio/presentation/admin/pages/admin_users_page.dart';
import 'package:resellio/presentation/admin/pages/admin_organizers_page.dart';
import 'package:resellio/presentation/admin/pages/admin_events_page.dart';
import 'package:resellio/presentation/admin/pages/admin_registration_page.dart';
import 'package:resellio/presentation/admin/pages/admin_overview_page.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  final List<AdminTab> _tabs = [
    AdminTab(
      title: 'Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    AdminTab(
      title: 'Users',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    AdminTab(
      title: 'Organizers',
      icon: Icons.verified_user_outlined,
      selectedIcon: Icons.verified_user,
    ),
    AdminTab(
      title: 'Events',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
    ),
    AdminTab(
      title: 'Add Admin',
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedIndex = _tabController.index;
      });
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
        tabController: _tabController,
        selectedIndex: _selectedIndex,
        onTabChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _tabController.animateTo(index);
        },
      ),
    );
  }
}

class _AdminMainView extends StatelessWidget {
  final List<AdminTab> tabs;
  final TabController tabController;
  final int selectedIndex;
  final Function(int) onTabChanged;

  const _AdminMainView({
    required this.tabs,
    required this.tabController,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  Widget _getSelectedPage() {
    switch (selectedIndex) {
      case 0:
        return const AdminOverviewPage();
      case 1:
        return const AdminUsersPage();
      case 2:
        return const AdminOrganizersPage();
      case 3:
        return const AdminEventsPage();
      case 4:
        return const AdminRegistrationPage();
      default:
        return const AdminOverviewPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);

    return PageLayout(
      title: 'Admin Panel',
      showCartButton: false,
      actions: [
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
      ],
      body: Column(
        children: [
          // Tab Navigation
          Container(
            color: colorScheme.surface,
            child: isMobile
                ? _buildMobileTabBar(theme, colorScheme)
                : _buildDesktopTabBar(theme, colorScheme),
          ),
          // Content
          Expanded(child: _getSelectedPage()),
        ],
      ),
    );
  }

  Widget _buildMobileTabBar(ThemeData theme, ColorScheme colorScheme) {
    return TabBar(
      controller: tabController,
      isScrollable: true,
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: colorScheme.primary,
      indicatorWeight: 3,
      tabs: tabs.map((tab) => Tab(text: tab.title)).toList(),
    );
  }

  Widget _buildDesktopTabBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == selectedIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTabChanged(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? tab.selectedIcon : tab.icon,
                        size: 20,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
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
        }).toList(),
      ),
    );
  }
}

class AdminTab {
  final String title;
  final IconData icon;
  final IconData selectedIcon;

  AdminTab({
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });
}