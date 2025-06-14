import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/services/api_service.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class AdminOrganizerVerificationPage extends StatefulWidget {
  const AdminOrganizerVerificationPage({super.key});

  @override
  State<AdminOrganizerVerificationPage> createState() => _AdminOrganizerVerificationPageState();
}

class _AdminOrganizerVerificationPageState extends State<AdminOrganizerVerificationPage> {
  List<dynamic> _pendingOrganizers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingOrganizers();
  }

  Future<void> _loadPendingOrganizers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final response = await apiService.get(
        '/api/auth/pending-organizers',
        headers: context.read<AuthService>().user != null
            ? {'Authorization': 'Bearer ${context.read<AuthService>().user}'}
            : {},
      );

      setState(() {
        _pendingOrganizers = response.data as List;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOrganizer(dynamic organizer, bool approve) async {
    final action = approve ? 'approve' : 'reject';
    final confirmed = await _showConfirmDialog(
      '${approve ? 'Approve' : 'Reject'} Organizer',
      'Are you sure you want to $action ${organizer['first_name']} ${organizer['last_name']} from ${organizer['company_name']}?',
      approve,
    );

    if (confirmed) {
      try {
        final apiService = context.read<ApiService>();
        await apiService.post(
          '/api/auth/verify-organizer',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${context.read<AuthService>().user}',
          },
          json_data: {
            'organizer_id': organizer['organizer_id'],
            'approve': approve,
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Organizer ${organizer['first_name']} ${organizer['last_name']} has been ${approve ? 'approved' : 'rejected'}',
              ),
              backgroundColor: approve ? Colors.green : Colors.orange,
            ),
          );
          _loadPendingOrganizers(); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to $action organizer: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content, bool isApproval) async {
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
              backgroundColor: isApproval ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(isApproval ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showOrganizerDetails(dynamic organizer) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        '${organizer['first_name']?[0] ?? ''}${organizer['last_name']?[0] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${organizer['first_name']} ${organizer['last_name']}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            organizer['company_name'] ?? 'Unknown Company',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Personal Information', [
                        _buildDetailRow('Full Name', '${organizer['first_name']} ${organizer['last_name']}'),
                        _buildDetailRow('Email', organizer['email']),
                        _buildDetailRow('Login', organizer['login']),
                      ]),

                      const SizedBox(height: 20),

                      _buildDetailSection('Business Information', [
                        _buildDetailRow('Company Name', organizer['company_name'] ?? 'Not provided'),
                        _buildDetailRow('User ID', organizer['user_id']?.toString() ?? 'Unknown'),
                        _buildDetailRow('Organizer ID', organizer['organizer_id']?.toString() ?? 'Unknown'),
                        _buildDetailRow('Status', organizer['is_verified'] ? 'Verified' : 'Pending Verification'),
                      ]),

                      const SizedBox(height: 20),

                      _buildDetailSection('Account Status', [
                        _buildDetailRow('Active', organizer['is_active'] ? 'Yes' : 'No'),
                        _buildDetailRow('Account Type', organizer['user_type'] ?? 'Unknown'),
                      ]),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _verifyOrganizer(organizer, false);
                        },
                        icon: const Icon(Icons.close, color: Colors.orange),
                        label: const Text('Reject', style: TextStyle(color: Colors.orange)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _verifyOrganizer(organizer, true);
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Organizer Verification',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadPendingOrganizers,
        ),
      ],
      body: _buildBody(),
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
              onPressed: _loadPendingOrganizers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pendingOrganizers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'All organizers verified!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No pending organizer verifications at the moment.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingOrganizers.length,
      itemBuilder: (context, index) {
        final organizer = _pendingOrganizers[index];
        return _buildOrganizerCard(organizer);
      },
    );
  }

  Widget _buildOrganizerCard(dynamic organizer) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and basic info
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${organizer['first_name']?[0] ?? ''}${organizer['last_name']?[0] ?? ''}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${organizer['first_name']} ${organizer['last_name']}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        organizer['email'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Company information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Company: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      organizer['company_name'] ?? 'Not provided',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOrganizerDetails(organizer),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _verifyOrganizer(organizer, false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verifyOrganizer(organizer, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
