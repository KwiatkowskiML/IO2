import 'package:flutter/material.dart';
import 'package:resellio/core/utils/responsive_layout.dart';
import 'package:resellio/presentation/common_widgets/logout_button.dart';
import 'package:resellio/presentation/auth/widgets/app_branding.dart';
import 'package:resellio/presentation/events/pages/event_browse_page.dart';
import 'package:resellio/presentation/tickets/pages/my_tickets_page.dart';
import 'package:resellio/presentation/marketplace/pages/marketplace_page.dart';
import 'package:resellio/presentation/profile/pages/profile_page.dart';
import 'package:resellio/presentation/organizer/pages/organizer_dashboard_page.dart';
import 'package:resellio/presentation/admin/pages/admin_dashboard_page.dart';
import 'package:resellio/presentation/organizer/pages/organizer_events_page.dart';
import 'package:resellio/core/models/user_model.dart';

class AdaptiveNavigation extends StatefulWidget {
  final UserRole userRole;
  final Widget body;

  const AdaptiveNavigation({
    super.key,
    required this.userRole,
    required this.body,
  });

  @override
  State<AdaptiveNavigation> createState() => _AdaptiveNavigationState();
}

class _AdaptiveNavigationState extends State<AdaptiveNavigation> {
  int _selectedIndex = 0;

  List<Widget> _getScreens() {
    switch (widget.userRole) {
      case UserRole.customer:
        return [
          const EventBrowsePage(),
          const MyTicketsPage(),
          const MarketplacePage(),
          const ProfilePage(),
        ];
      case UserRole.organizer:
        return [
          const OrganizerDashboardPage(),
          const OrganizerEventsPage(),
          const ProfilePage(),
        ];
      case UserRole.admin:
        return [
          const AdminMainPage(),
          const Center(child: Text('Direct User Management - Use Admin Panel instead')),
          const Center(child: Text('Direct Organizer Management - Use Admin Panel instead')),
          const ProfilePage(),
        ];
    }
  }

  List<NavigationDestination> _getBottomNavDestinations() {
    switch (widget.userRole) {
      case UserRole.customer:
        return const [
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'My Tickets',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'Marketplace',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      case UserRole.organizer:
        return const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'My Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      case UserRole.admin:
        return const [
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: 'Organizers',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
    }
  }

  List<NavigationRailDestination> _getNavRailDestinations() {
    switch (widget.userRole) {
      case UserRole.customer:
        return const [
          NavigationRailDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: Text('Events'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: Text('My Tickets'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: Text('Marketplace'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: Text('Profile'),
          ),
        ];
      case UserRole.organizer:
        return const [
          NavigationRailDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: Text('Dashboard'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: Text('My Events'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: Text('Profile'),
          ),
        ];
      case UserRole.admin:
        return const [
          NavigationRailDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: Text('Admin Panel'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: Text('Users'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: Text('Organizers'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: Text('Profile'),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool showNavRail =
        ResponsiveLayout.isTablet(context) ||
            ResponsiveLayout.isDesktop(context);
    final bool isExtended = ResponsiveLayout.isDesktop(context);
    final screens = _getScreens();

    if (showNavRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: colorScheme.surface,
              selectedIconTheme: IconThemeData(color: colorScheme.primary),
              unselectedIconTheme: IconThemeData(
                color: colorScheme.onSurfaceVariant,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
              selectedLabelTextStyle: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              useIndicator: true,
              indicatorColor: colorScheme.primaryContainer,
              labelType:
              isExtended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: _getNavRailDestinations(),
              extended: isExtended,
              elevation: 2,
              leading:
              isExtended
                  ? Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: 8.0,
                ),
                child: AppBranding(
                  logoSize: 64,
                  alignment: Alignment.centerLeft,
                  textAlign: TextAlign.left,
                ),
              )
                  : Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const AppBranding(
                      logoSize: 40,
                      showTitle: false,
                      showTagline: false,
                    ),
                  ),
                ],
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: LogoutButton(isExtended: isExtended),
                  ),
                ),
              ),
              minWidth: 72,
              minExtendedWidth: 280,
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: screens,
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: _getBottomNavDestinations(),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: colorScheme.primaryContainer,
          shadowColor: Colors.black.withOpacity(0.1),
          elevation: 2,
        ),
      );
    }
  }
}
