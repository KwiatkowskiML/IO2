import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:resellio/core/services/api_service.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? _stats;
  List<dynamic> _pendingOrganizers = [];
  List<dynamic> _pendingEvents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();

      // Load user statistics
      final stats = await apiService.getUserStats();

      // Load pending organizers
      final pendingOrganizers = await apiService.getPendingOrganizers();

      // Load pending events
      final pendingEvents = await apiService.getPendingEvents();

      setState(() {
        _stats = stats;
        _pendingOrganizers = pendingOrganizers;
        _pendingEvents = pendingEvents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Admin Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDashboardData,
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildSystemOverview(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildPendingTasks(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final authService = context.read<AuthService>();
    final user = authService.user;

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.red.shade600,
              Colors.red.shade400,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Administrator!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'System status and administrative controls',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOverview() {
    if (_stats == null) return const SizedBox.shrink();

    final totalUsers = _stats!['total_users'] ?? 0;
    final activeUsers = _stats!['active_users'] ?? 0;
    final bannedUsers = _stats!['banned_users'] ?? 0;
    final usersByType = _stats!['users_by_type'] ?? {};
    final organizerStats = _stats!['organizer_stats'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Users',
                value: totalUsers.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Active Users',
                value: activeUsers.toString(),
                icon: Icons.person_add_alt_1,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Customers',
                value: (usersByType['customers'] ?? 0).toString(),
                icon: Icons.person,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Organizers',
                value: (usersByType['organizers'] ?? 0).toString(),
                icon: Icons.business,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Pending Verifications',
                value: (organizerStats['pending'] ?? 0).toString(),
                icon: Icons.pending_actions,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Banned Users',
                value: bannedUsers.toString(),
                icon: Icons.person_off,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Manage Users',
                description: 'View and manage all users',
                icon: Icons.people_outline,
                color: Colors.blue,
                onTap: () => context.go('/admin/users'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Verify Organizers',
                description: 'Review pending verifications',
                icon: Icons.verified_user_outlined,
                color: Colors.green,
                onTap: () => context.go('/admin/organizers'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Authorize Events',
                description: 'Review pending events',
                icon: Icons.event_available_outlined,
                color: Colors.purple,
                onTap: () => context.go('/admin/events'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'System Settings',
                description: 'Configure system parameters',
                icon: Icons.settings_outlined,
                color: Colors.orange,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('System Settings - Coming Soon!')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingTasks() {
    final pendingOrganizerCount = _pendingOrganizers.length;
    final pendingEventCount = _pendingEvents.length;
    final totalPending = pendingOrganizerCount + pendingEventCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pending Tasks',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (totalPending > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  totalPending.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (totalPending == 0)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All tasks completed!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No pending tasks at the moment',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          if (pendingOrganizerCount > 0)
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.verified_user, color: Colors.orange),
                ),
                title: Text('Organizer Verifications'),
                subtitle: Text('$pendingOrganizerCount pending verification(s)'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.go('/admin/organizers'),
              ),
            ),
          if (pendingEventCount > 0)
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event_available, color: Colors.purple),
                ),
                title: Text('Event Authorizations'),
                subtitle: Text('$pendingEventCount pending authorization(s)'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.go('/admin/events'),
              ),
            ),
        ],
      ],
    );
  }
}