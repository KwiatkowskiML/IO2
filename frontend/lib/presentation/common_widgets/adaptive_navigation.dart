import 'package:flutter/material.dart';
import 'package:resellio/core/utils/responsive_layout.dart';
import 'package:resellio/presentation/common_widgets/logout_button.dart';
import 'package:resellio/presentation/auth/widgets/app_branding.dart';

enum UserRole { user, organizer, admin }

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



  List<NavigationDestination> _getBottomNavDestinations() {
    switch (widget.userRole) {
      case UserRole.user:
        return const [
          NavigationDestination(icon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.confirmation_number), label: 'My Tickets'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Marketplace'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ];
      case UserRole.organizer:
        return const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.add_circle), label: 'Create'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Statistics'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ];
      case UserRole.admin:
        return const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.verified), label: 'Verify'),
          NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ];
    }
  }

  List<NavigationRailDestination> _getNavRailDestinations() {
    switch (widget.userRole) {
      case UserRole.user:
        return const [
          NavigationRailDestination(icon: Icon(Icons.event), label: Text('Events')),
          NavigationRailDestination(icon: Icon(Icons.confirmation_number), label: Text('My Tickets')),
          NavigationRailDestination(icon: Icon(Icons.store), label: Text('Marketplace')),
          NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profile')),
        ];
      case UserRole.organizer:
        return const [
          NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
          NavigationRailDestination(icon: Icon(Icons.add_circle), label: Text('Create')),
          NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Statistics')),
          NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profile')),
        ];
      case UserRole.admin:
        return const [
          NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
          NavigationRailDestination(icon: Icon(Icons.people), label: Text('Users')),
          NavigationRailDestination(icon: Icon(Icons.verified), label: Text('Verify')),
          NavigationRailDestination(icon: Icon(Icons.admin_panel_settings), label: Text('Admin')),
        ];
    }
  }



  Widget _getSelectedScreen() {
    List<Widget> screens;
    switch (widget.userRole) {
      case UserRole.user:
        screens = [
          const Center(child: Text('Events Page (User)')),
          const Center(child: Text('My Tickets Page (User)')),
          const Center(child: Text('Marketplace Page (User)')),
          const Center(child: Text('Profile Page (User)')),
        ];
        break;
      case UserRole.organizer:
        screens = [
          const Center(child: Text('Dashboard Page (Organizer)')),
          const Center(child: Text('Create Event Page (Organizer)')),
          const Center(child: Text('Statistics Page (Organizer)')),
          const Center(child: Text('Profile Page (Organizer)')),
        ];
        break;
      case UserRole.admin:
        screens = [
          const Center(child: Text('Dashboard Page (Admin)')),
          const Center(child: Text('User Management Page (Admin)')),
          const Center(child: Text('Verification Page (Admin)')),
          const Center(child: Text('Admin Settings Page (Admin)')),
        ];
        break;
    }

    if (_selectedIndex >= screens.length) {
      return const Center(child: Text('Error: Invalid page index'));
    }
    return screens[_selectedIndex];

  }


  @override
  Widget build(BuildContext context) {
    final bool showNavRail = ResponsiveLayout.isTablet(context) || ResponsiveLayout.isDesktop(context);
    final bool isExtended = ResponsiveLayout.isDesktop(context);

    if (showNavRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() { _selectedIndex = index; });
              },
              labelType: isExtended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              destinations: _getNavRailDestinations(),
              extended: isExtended,
              leading: isExtended
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: AppBranding(logoSize: 64, alignment: Alignment.centerLeft, textAlign: TextAlign.left),
              )
                  : const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: AppBranding(logoSize: 40),
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
              minWidth: 56,
              minExtendedWidth: 270,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: _getSelectedScreen(),
            ),
          ],
        ),
      );
    } else {

      return Scaffold(
        body: _getSelectedScreen(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() { _selectedIndex = index; });
          },
          destinations: _getBottomNavDestinations(),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      );
    }
  }
}