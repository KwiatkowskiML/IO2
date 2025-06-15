import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_cubit.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_state.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/common_widgets/list_item_card.dart';
import 'package:resellio/presentation/common_widgets/dialogs.dart';
import 'package:resellio/presentation/common_widgets/empty_state_widget.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  UserFilter _selectedFilter = UserFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserDetails(BuildContext context, UserDetails user) {
    showDialog(
      context: context,
      builder: (context) => _UserDetailsDialog(user: user),
    );
  }

  void _showBanConfirmation(BuildContext context, UserDetails user) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Ban User',
      content: Text(
        'Are you sure you want to ban ${user.firstName} ${user.lastName}?\n\n'
            'This will prevent them from accessing the platform.',
      ),
      confirmText: 'Ban User',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      context.read<AdminDashboardCubit>().banUser(user.userId);
    }
  }

  void _showUnbanConfirmation(BuildContext context, UserDetails user) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Unban User',
      content: Text(
        'Are you sure you want to unban ${user.firstName} ${user.lastName}?\n\n'
            'This will restore their access to the platform.',
      ),
      confirmText: 'Unban User',
    );

    if (confirmed == true && mounted) {
      context.read<AdminDashboardCubit>().unbanUser(user.userId);
    }
  }

  List<UserDetails> _filterUsers(List<UserDetails> users) {
    var filtered = users;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final searchLower = _searchQuery.toLowerCase();
        return user.firstName.toLowerCase().contains(searchLower) ||
            user.lastName.toLowerCase().contains(searchLower) ||
            user.email.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Apply status filter
    switch (_selectedFilter) {
      case UserFilter.active:
        filtered = filtered.where((user) => user.isActive).toList();
        break;
      case UserFilter.banned:
        filtered = filtered.where((user) => !user.isActive).toList();
        break;
      case UserFilter.customers:
        filtered = filtered.where((user) => user.userType == 'customer').toList();
        break;
      case UserFilter.organizers:
        filtered = filtered.where((user) => user.userType == 'organizer').toList();
        break;
      case UserFilter.admins:
        filtered = filtered.where((user) => user.userType == 'administrator').toList();
        break;
      case UserFilter.all:
      default:
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        return BlocStateWrapper<AdminDashboardLoaded>(
          state: state,
          onRetry: () => context.read<AdminDashboardCubit>().loadDashboard(),
          builder: (loadedState) {
            final filteredUsers = _filterUsers(loadedState.allUsers);

            return Column(
              children: [
                // Search and Filter Controls
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: colorScheme.surface,
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search users by name or email...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: UserFilter.values.map((filter) {
                            final isSelected = filter == _selectedFilter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(_getFilterLabel(filter)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
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
                    ],
                  ),
                ),
                // Users List
                Expanded(
                  child: filteredUsers.isEmpty
                      ? EmptyStateWidget(
                    icon: Icons.people_outline,
                    message: _searchQuery.isNotEmpty
                        ? 'No users found'
                        : 'No users match the selected filter',
                    details: _searchQuery.isNotEmpty
                        ? 'Try adjusting your search terms'
                        : 'Try selecting a different filter',
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isProcessing = state is UserBanInProgress &&
                          state.userId == user.userId ||
                          state is UserUnbanInProgress &&
                              state.userId == user.userId;

                      return _UserCard(
                        user: user,
                        isProcessing: isProcessing,
                        onViewDetails: () => _showUserDetails(context, user),
                        onBan: user.isActive
                            ? () => _showBanConfirmation(context, user)
                            : () => _showUnbanConfirmation(context, user),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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
    }
  }
}

class _UserCard extends StatelessWidget {
  final UserDetails user;
  final bool isProcessing;
  final VoidCallback onViewDetails;
  final VoidCallback onBan;

  const _UserCard({
    required this.user,
    required this.isProcessing,
    required this.onViewDetails,
    required this.onBan,
  });

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userTypeColor = _getUserTypeColor(user.userType);

    return ListItemCard(
      isProcessing: isProcessing,
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
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: userTypeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.userType.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: userTypeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: user.isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.isActive ? 'ACTIVE' : 'BANNED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: user.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomContent: OverflowBar(
        alignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: isProcessing ? null : onViewDetails,
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Details'),
          ),
          TextButton.icon(
            onPressed: isProcessing ? null : onBan,
            icon: Icon(
              user.isActive ? Icons.block : Icons.check_circle,
              size: 18,
            ),
            label: Text(user.isActive ? 'Ban' : 'Unban'),
            style: TextButton.styleFrom(
              foregroundColor: user.isActive ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserDetailsDialog extends StatelessWidget {
  final UserDetails user;

  const _UserDetailsDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              '${user.firstName[0]}${user.lastName[0]}',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${user.firstName} ${user.lastName}'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Email', user.email),
            _buildDetailRow('User Type', user.userType.toUpperCase()),
            _buildDetailRow('Status', user.isActive ? 'Active' : 'Banned'),
            _buildDetailRow('User ID', user.userId.toString()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

enum UserFilter {
  all,
  active,
  banned,
  customers,
  organizers,
  admins,
}