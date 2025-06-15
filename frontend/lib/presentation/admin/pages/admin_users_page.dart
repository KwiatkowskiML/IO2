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

  // Pagination and filtering state
  int _currentPage = 1;
  static const int _pageSize = 20;
  String _searchQuery = '';
  UserFilter _selectedFilter = UserFilter.all;
  bool? _isActiveFilter;
  bool? _isVerifiedFilter;

  // Loading and data state
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

      // Prepare filters for backend
      String? userType;
      bool? isActive = _isActiveFilter;
      bool? isVerified = _isVerifiedFilter;

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

        if (!reset) {
          _currentPage++;
        }
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

    // Debounce search
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

  void _showUserDetails(BuildContext context, UserDetails user) {
    showDialog(
      context: context,
      builder: (context) => _UserDetailsDialog(user: user),
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

        // Update the local user state
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
            content: Text(user.isActive
                ? 'User banned successfully'
                : 'User unbanned successfully'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Search and Filter Controls
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
          ),
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
                      _onSearchChanged('');
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _onSearchChanged,
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
                        onSelected: (selected) => _onFilterChanged(filter),
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
          child: _users.isEmpty && !_isLoading
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
            itemCount: _users.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Loading indicator at the end
              if (index == _users.length) {
                if (_hasMore && !_isLoading) {
                  // Trigger loading more items
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
            onPressed: onViewDetails,
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Details'),
          ),
          TextButton.icon(
            onPressed: onBanToggle,
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
  verified,
  unverified,
}