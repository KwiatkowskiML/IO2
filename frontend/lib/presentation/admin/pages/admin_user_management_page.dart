import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/services/api_service.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  String? _error;

  // Filter controls
  String _searchQuery = '';
  String? _selectedUserType;
  bool? _isActiveFilter;
  bool? _isVerifiedFilter;
  int _currentPage = 1;
  final int _pageSize = 20;

  final _searchController = TextEditingController();

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

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();

      // Build query parameters
      Map<String, String> params = {
        'page': _currentPage.toString(),
        'limit': _pageSize.toString(),
      };

      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }
      if (_selectedUserType != null) {
        params['user_type'] = _selectedUserType!;
      }
      if (_isActiveFilter != null) {
        params['is_active'] = _isActiveFilter!.toString();
      }
      if (_isVerifiedFilter != null) {
        params['is_verified'] = _isVerifiedFilter!.toString();
      }

      final response = await apiService.request(
        'GET',
        '/auth/users?' + params.entries.map((e) => '${e.key}=${e.value}').join('&'),
        headers: context.read<AuthService>().user != null
            ? {'Authorization': 'Bearer ${context.read<AuthService>().user}'}
            : {},
      );

      setState(() {
        _users = response.data as List;
        _filteredUsers = _users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _banUser(int userId, String userName) async {
    final confirmed = await _showConfirmDialog(
      'Ban User',
      'Are you sure you want to ban $userName? This will prevent them from accessing their account.',
    );

    if (confirmed) {
      try {
        final apiService = context.read<ApiService>();
        await apiService.request(
          'POST',
          '/auth/ban-user/$userId',
          headers: context.read<AuthService>().user != null
              ? {'Authorization': 'Bearer ${context.read<AuthService>().user}'}
              : {},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$userName has been banned'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadUsers(); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to ban user: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _unbanUser(int userId, String userName) async {
    final confirmed = await _showConfirmDialog(
      'Unban User',
      'Are you sure you want to unban $userName? This will restore their account access.',
    );

    if (confirmed) {
      try {
        final apiService = context.read<ApiService>();
        await apiService.request(
          'POST',
          '/auth/unban-user/$userId',
          headers: context.read<AuthService>().user != null
              ? {'Authorization': 'Bearer ${context.read<AuthService>().user}'}
              : {},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$userName has been unbanned'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers(); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unban user: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showUserDetails(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user['first_name']} ${user['last_name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user['email']),
              _buildDetailRow('Login', user['login']),
              _buildDetailRow('User Type', user['user_type']),
              _buildDetailRow('Status', user['is_active'] ? 'Active' : 'Banned'),
              if (user['user_type'] == 'organizer') ...[
                const SizedBox(height: 16),
                const Text('Organizer Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow('Company', user['company_name'] ?? 'N/A'),
                _buildDetailRow('Verified', user['is_verified'] ? 'Yes' : 'No'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedUserType = null;
      _isActiveFilter = null;
      _isVerifiedFilter = null;
      _currentPage = 1;
    });
    _searchController.clear();
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'User Management',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadUsers,
        ),
      ],
      body: Column(
        children: [
          // Search and Filter Section
          _buildFilterSection(),

          // Users List
          Expanded(
            child: _buildUsersList(),
          ),

          // Pagination
          if (_users.isNotEmpty) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by email, login, or name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _loadUsers();
                  },
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 1;
                });
                _loadUsers();
              },
            ),

            const SizedBox(height: 16),

            // Filter Chips
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: Text('User Type: ${_selectedUserType ?? 'All'}'),
                  selected: _selectedUserType != null,
                  onSelected: (_) => _showUserTypeFilter(),
                ),
                FilterChip(
                  label: Text('Status: ${_isActiveFilter == null ? 'All' : _isActiveFilter! ? 'Active' : 'Banned'}'),
                  selected: _isActiveFilter != null,
                  onSelected: (_) => _showStatusFilter(),
                ),
                if (_selectedUserType == 'organizer')
                  FilterChip(
                    label: Text('Verified: ${_isVerifiedFilter == null ? 'All' : _isVerifiedFilter! ? 'Yes' : 'No'}'),
                    selected: _isVerifiedFilter != null,
                    onSelected: (_) => _showVerifiedFilter(),
                  ),
                if (_selectedUserType != null || _isActiveFilter != null || _isVerifiedFilter != null)
                  ActionChip(
                    label: const Text('Clear All'),
                    onPressed: _clearFilters,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUserTypeFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by User Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All'),
              onTap: () {
                setState(() {
                  _selectedUserType = null;
                  _currentPage = 1;
                });
                Navigator.pop(context);
                _loadUsers();
              },
            ),
            ListTile(
              title: const Text('Customer'),
              onTap: () {
                setState(() {
                  _selectedUserType = 'customer';
                  _currentPage = 1;
                });
                Navigator.pop(context);
                _loadUsers();
              },
            ),
            ListTile(
              title: const Text('Organizer'),
              onTap: () {
                setState(() {
                  _selectedUserType = 'organizer';
                  _currentPage = 1;
                });
                Navigator.pop(context);
                _loadUsers();
              },
            ),
            ListTile(
              title: const Text('Administrator'),
              onTap: () {
                setState(() {
                  _selectedUserType = 'administrator';
                  _currentPage = 1;
                });
                Navigator.pop(context);
                _loadUsers();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All'),
              onTap: () {
                setState(() {
                  _isActiveFilter = null;
                  _currentPage = 1;
                });
                Navigator.pop(context);
                _loadUsers();
              },
            ),
            ListTile(
              title: const Text('Active'),
              onTap: () {
                setState(() {
                  _isActiveFilter = true;
                  _currentPage = 1;
                });
                Navigator.pop(context);
                _loadUsers();
              },
            ),
            ListTile(
              title: const Text('Banned'),
              onTap: () {
                setState(() {
                  _isActiveFilter = false;
                  _currentPage = 1;
                });
                Navigator.pop(context);
                _loadUsers();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVerifiedFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All'),
              onTap: () {
                setState(() {
                  _isVerifiedFilter = null;
                  _currentPage = 1;
                });
                Navigator.pop(context);
                _loadUsers();
              },
            ),
            ListTile(
              title: const Text('Verified'),
              onTap: () {
                setState(() {
                  _isVerifiedFilter = true;
                  _currentPage = 1;
                });
                Navigator.pop(context);
                _loadUsers();
              },
            ),
            ListTile(
              title: const Text('Pending'),
              onTap: () {
                setState(() {
                  _isVerifiedFilter = false;
                  _currentPage = 1;
                });
                Navigator.pop(context);
                _loadUsers();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(dynamic user) {
    final theme = Theme.of(context);
    final isActive = user['is_active'] as bool;
    final userType = user['user_type'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getUserTypeColor(userType),
          child: Text(
            '${user['first_name']?[0] ?? ''}${user['last_name']?[0] ?? ''}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${user['first_name']} ${user['last_name']}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email']),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getUserTypeColor(userType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getUserTypeColor(userType)),
                  ),
                  child: Text(
                    userType.toUpperCase(),
                    style: TextStyle(
                      color: _getUserTypeColor(userType),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isActive ? Colors.green : Colors.red),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'BANNED',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (userType == 'organizer' && user['is_verified'] != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: user['is_verified']
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: user['is_verified'] ? Colors.blue : Colors.orange),
                    ),
                    child: Text(
                      user['is_verified'] ? 'VERIFIED' : 'PENDING',
                      style: TextStyle(
                        color: user['is_verified'] ? Colors.blue : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'details':
                _showUserDetails(user);
                break;
              case 'ban':
                _banUser(user['user_id'], '${user['first_name']} ${user['last_name']}');
                break;
              case 'unban':
                _unbanUser(user['user_id'], '${user['first_name']} ${user['last_name']}');
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            if (isActive)
              const PopupMenuItem(
                value: 'ban',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Ban User', style: TextStyle(color: Colors.red)),
                  ],
                ),
              )
            else
              const PopupMenuItem(
                value: 'unban',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Unban User', style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case 'customer':
        return Colors.green;
      case 'organizer':
        return Colors.blue;
      case 'administrator':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentPage > 1
                ? () {
              setState(() {
                _currentPage--;
              });
              _loadUsers();
            }
                : null,
            child: const Text('Previous'),
          ),
          Text(
            'Page $_currentPage',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ElevatedButton(
            onPressed: _users.length == _pageSize
                ? () {
              setState(() {
                _currentPage++;
              });
              _loadUsers();
            }
                : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}