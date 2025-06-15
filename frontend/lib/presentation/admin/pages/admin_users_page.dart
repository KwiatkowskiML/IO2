import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_cubit.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_state.dart';
import 'package:resellio/presentation/admin/widgets/admin_card.dart';
import 'package:resellio/presentation/admin/widgets/admin_section_header.dart';
import 'package:resellio/presentation/admin/widgets/admin_action_buttons.dart';
import 'package:resellio/presentation/admin/widgets/admin_status_chip.dart';
import 'package:resellio/presentation/admin/widgets/admin_detail_dialog.dart';
import 'package:resellio/presentation/common_widgets/dialogs.dart';
import 'package:resellio/presentation/common_widgets/empty_state_widget.dart';
import 'package:resellio/presentation/common_widgets/list_item_card.dart';

enum UserFilter {
  all,
  active,
  banned,
  customers,
  organizers,
  admins,
  verified,
  unverified,
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _pageSize = 20;
  String _searchQuery = '';
  UserFilter _selectedFilter = UserFilter.all;
  List<UserDetails> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool reset = false}) async {
    if (_isLoading) return;

    if (reset) {
      _currentPage = 1;
      _users.clear();
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final adminCubit = context.read<AdminDashboardCubit>();
      String? userType;
      bool? isActive;
      bool? isVerified;

      switch (_selectedFilter) {
        case UserFilter.active:
          isActive = true;
          break;
        case UserFilter.banned:
          isActive = false;
          break;
        case UserFilter.customers:
          userType = 'customer';
          break;
        case UserFilter.organizers:
          userType = 'organizer';
          break;
        case UserFilter.admins:
          userType = 'administrator';
          break;
        case UserFilter.verified:
          userType = 'organizer';
          isVerified = true;
          break;
        case UserFilter.unverified:
          userType = 'organizer';
          isVerified = false;
          break;
        case UserFilter.all:
        default:
          break;
      }

      final newUsers = await adminCubit.loadUsers(
        page: _currentPage,
        limit: _pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        userType: userType,
        isActive: isActive,
        isVerified: isVerified,
      );

      setState(() {
        if (reset) {
          _users = newUsers;
        } else {
          _users.addAll(newUsers);
        }
        _hasMore = newUsers.length == _pageSize;
        _isLoading = false;
        if (!reset) _currentPage++;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchQuery == value) {
        _loadUsers(reset: true);
      }
    });
  }

  void _onFilterChanged(UserFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadUsers(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminCard(
          header: AdminSectionHeader(
            icon: Icons.people,
            title: 'User Management',
            subtitle: 'Manage all system users',
          ),
          child: Column(
            children: [
              _SearchBar(
                controller: _searchController,
                searchQuery: _searchQuery,
                onSearchChanged: _onSearchChanged,
              ),
              const SizedBox(height: 16),
              _FilterChips(
                selectedFilter: _selectedFilter,
                onFilterChanged: _onFilterChanged,
              ),
            ],
          ),
        ),
        Expanded(
          child: _users.isEmpty && !_isLoading
              ? EmptyStateWidget(
            icon: Icons.people_outline,
            message: _searchQuery.isNotEmpty ? 'No users found' : 'No users match the selected filter',
            details: _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Try selecting a different filter',
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _users.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _users.length) {
                if (_hasMore && !_isLoading) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadUsers();
                  });
                }
                return _isLoading
                    ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
                    : const SizedBox.shrink();
              }

              final user = _users[index];
              return _UserCard(
                user: user,
                onViewDetails: () => _showUserDetails(context, user),
                onBanToggle: () => _showBanConfirmation(context, user),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showUserDetails(BuildContext context, UserDetails user) {
    showDialog(
      context: context,
      builder: (context) => AdminDetailDialog(
        icon: Icons.person,
        title: '${user.firstName} ${user.lastName}',
        subtitle: 'User Details',
        sections: [
          AdminDetailSection(
            title: 'User Information',
            rows: [
              AdminDetailRow(label: 'Email', value: user.email),
              AdminDetailRow(label: 'User Type', value: user.userType.toUpperCase()),
              AdminDetailRow(label: 'Status', value: user.isActive ? 'Active' : 'Banned'),
              AdminDetailRow(label: 'User ID', value: user.userId.toString()),
            ],
          ),
        ],
      ),
    );
  }

  void _showBanConfirmation(BuildContext context, UserDetails user) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: user.isActive ? 'Ban User' : 'Unban User',
      content: Text(
        user.isActive
            ? 'Are you sure you want to ban ${user.firstName} ${user.lastName}?\n\n'
            'This will prevent them from accessing the platform.'
            : 'Are you sure you want to unban ${user.firstName} ${user.lastName}?\n\n'
            'This will restore their access to the platform.',
      ),
      confirmText: user.isActive ? 'Ban User' : 'Unban User',
      isDestructive: user.isActive,
    );

    if (confirmed == true && mounted) {
      try {
        final adminCubit = context.read<AdminDashboardCubit>();
        if (user.isActive) {
          await adminCubit.banUser(user.userId);
        } else {
          await adminCubit.unbanUser(user.userId);
        }

        setState(() {
          final index = _users.indexWhere((u) => u.userId == user.userId);
          if (index != -1) {
            _users[index] = UserDetails(
              userId: user.userId,
              email: user.email,
              firstName: user.firstName,
              lastName: user.lastName,
              userType: user.userType,
              isActive: !user.isActive,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(user.isActive ? 'User banned successfully' : 'User unbanned successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _getFilterLabel(UserFilter filter) {
    switch (filter) {
      case UserFilter.all:
        return 'All Users';
      case UserFilter.active:
        return 'Active';
      case UserFilter.banned:
        return 'Banned';
      case UserFilter.customers:
        return 'Customers';
      case UserFilter.organizers:
        return 'Organizers';
      case UserFilter.admins:
        return 'Admins';
      case UserFilter.verified:
        return 'Verified';
      case UserFilter.unverified:
        return 'Unverified';
    }
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _SearchBar({
    required this.controller,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search users by name or email...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            controller.clear();
            onSearchChanged('');
          },
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: onSearchChanged,
    );
  }
}

class _FilterChips extends StatelessWidget {
  final UserFilter selectedFilter;
  final ValueChanged<UserFilter> onFilterChanged;

  const _FilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: UserFilter.values.map((filter) {
          final isSelected = filter == selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(_getFilterLabel(filter)),
              selected: isSelected,
              onSelected: (selected) => onFilterChanged(filter),
              backgroundColor: colorScheme.surfaceContainerHighest,
              selectedColor: colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterLabel(UserFilter filter) {
    switch (filter) {
      case UserFilter.all:
        return 'All Users';
      case UserFilter.active:
        return 'Active';
      case UserFilter.banned:
        return 'Banned';
      case UserFilter.customers:
        return 'Customers';
      case UserFilter.organizers:
        return 'Organizers';
      case UserFilter.admins:
        return 'Admins';
      case UserFilter.verified:
        return 'Verified';
      case UserFilter.unverified:
        return 'Unverified';
    }
  }
}

class _UserCard extends StatelessWidget {
  final UserDetails user;
  final VoidCallback onViewDetails;
  final VoidCallback onBanToggle;

  const _UserCard({
    required this.user,
    required this.onViewDetails,
    required this.onBanToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userTypeColor = _getUserTypeColor(user.userType);

    return ListItemCard(
      isDimmed: !user.isActive,
      leadingWidget: CircleAvatar(
        backgroundColor: userTypeColor.withOpacity(0.1),
        child: Text(
          '${user.firstName[0]}${user.lastName[0]}',
          style: TextStyle(
            color: userTypeColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text('${user.firstName} ${user.lastName}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(user.email),
          const SizedBox(height: 8),
          Row(
            children: [
              AdminStatusChip(
                type: AdminStatusType.waiting,
                customText: user.userType.toUpperCase(),
              ),
              const SizedBox(width: 8),
              AdminStatusChip(
                type: user.isActive ? AdminStatusType.active : AdminStatusType.banned,
              ),
            ],
          ),
        ],
      ),
      bottomContent: AdminActionButtons(
        actions: [
          AdminAction.secondary(
            label: 'Details',
            icon: Icons.info_outline,
            onPressed: onViewDetails,
          ),
          AdminAction(
            label: user.isActive ? 'Ban' : 'Unban',
            icon: user.isActive ? Icons.block : Icons.check_circle,
            onPressed: onBanToggle,
            color: user.isActive ? Colors.red : Colors.green,
          ),
        ],
      ),
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'administrator':
        return Colors.purple;
      case 'organizer':
        return Colors.blue;
      case 'customer':
      default:
        return Colors.green;
    }
  }
}