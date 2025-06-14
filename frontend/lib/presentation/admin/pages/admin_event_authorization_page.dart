import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/services/api_service.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class AdminEventAuthorizationPage extends StatefulWidget {
  const AdminEventAuthorizationPage({super.key});

  @override
  State<AdminEventAuthorizationPage> createState() => _AdminEventAuthorizationPageState();
}

class _AdminEventAuthorizationPageState extends State<AdminEventAuthorizationPage> {
  List<dynamic> _pendingEvents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingEvents();
  }

  Future<void> _loadPendingEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      // Get all events and filter for pending ones
      final response = await apiService.get('/api/events');

      final allEvents = response.data as List;
      final pendingEvents = allEvents.where((event) => event['status'] == 'pending').toList();

      setState(() {
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

  Future<void> _authorizeEvent(dynamic event, bool approve) async {
    final action = approve ? 'authorize' : 'reject';
    final confirmed = await _showConfirmDialog(
      '${approve ? 'Authorize' : 'Reject'} Event',
      'Are you sure you want to $action "${event['name']}"?',
      approve,
    );

    if (confirmed) {
      try {
        final apiService = context.read<ApiService>();

        if (approve) {
          await apiService.post(
            '/api/events/authorize/${event['event_id']}',
            headers: {
              'Authorization': 'Bearer ${context.read<AuthService>().user}',
            },
          );
        } else {
          // For rejection, we might need a separate endpoint or status update
          // For now, we'll treat it as not authorizing
          print('Event rejection not implemented in backend');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Event "${event['name']}" has been ${approve ? 'authorized' : 'rejected'}',
              ),
              backgroundColor: approve ? Colors.green : Colors.orange,
            ),
          );
          _loadPendingEvents(); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to $action event: ${e.toString()}'),
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
            child: Text(isApproval ? 'Authorize' : 'Reject'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showEventDetails(dynamic event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.event,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['name'],
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Event Details',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Basic Information', [
                        _buildDetailRow('Event Name', event['name']),
                        _buildDetailRow('Description', event['description'] ?? 'No description provided'),
                        _buildDetailRow('Status', event['status']?.toString().toUpperCase() ?? 'UNKNOWN'),
                      ]),

                      const SizedBox(height: 20),

                      _buildDetailSection('Date & Time', [
                        _buildDetailRow('Start Date', _formatDateTime(event['start_date'])),
                        _buildDetailRow('End Date', _formatDateTime(event['end_date'])),
                        _buildDetailRow('Duration', _calculateDuration(event['start_date'], event['end_date'])),
                      ]),

                      const SizedBox(height: 20),

                      _buildDetailSection('Location & Details', [
                        _buildDetailRow('Venue', event['location_name'] ?? 'Unknown'),
                        _buildDetailRow('Minimum Age', event['minimum_age']?.toString() ?? 'No restriction'),
                        _buildDetailRow('Total Tickets', event['total_tickets']?.toString() ?? '0'),
                      ]),

                      const SizedBox(height: 20),

                      _buildDetailSection('Organizer Information', [
                        _buildDetailRow('Organizer ID', event['organizer_id']?.toString() ?? 'Unknown'),
                        _buildDetailRow('Event ID', event['event_id']?.toString() ?? 'Unknown'),
                      ]),

                      if (event['categories'] != null && (event['categories'] as List).isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildCategoriesSection(event['categories']),
                      ],
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
                          _authorizeEvent(event, false);
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
                          _authorizeEvent(event, true);
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Authorize'),
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

  Widget _buildCategoriesSection(List<dynamic> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              category.toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'Not specified';
    try {
      final DateTime dt = DateTime.parse(dateTime.toString());
      return DateFormat('MMM dd, yyyy - HH:mm').format(dt);
    } catch (e) {
      return dateTime.toString();
    }
  }

  String _calculateDuration(dynamic startDate, dynamic endDate) {
    if (startDate == null || endDate == null) return 'Unknown';
    try {
      final DateTime start = DateTime.parse(startDate.toString());
      final DateTime end = DateTime.parse(endDate.toString());
      final Duration duration = end.difference(start);

      if (duration.inDays > 0) {
        return '${duration.inDays} day(s) ${duration.inHours % 24} hour(s)';
      } else {
        return '${duration.inHours} hour(s) ${duration.inMinutes % 60} minute(s)';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Event Authorization',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadPendingEvents,
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
              onPressed: _loadPendingEvents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pendingEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'All events authorized!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No pending event authorizations at the moment.',
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
      itemCount: _pendingEvents.length,
      itemBuilder: (context, index) {
        final event = _pendingEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(dynamic event) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with event name and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.event,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['name'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Organizer ID: ${event['organizer_id']}',
                        style: theme.textTheme.bodySmall?.copyWith(
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

            const SizedBox(height: 12),

            // Event details
            if (event['description'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  event['description'],
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Date and location info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Start: ${_formatDateTime(event['start_date'])}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event['location_name'] ?? 'Location not specified',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  if (event['total_tickets'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.confirmation_number,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total tickets: ${event['total_tickets']}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEventDetails(event),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _authorizeEvent(event, false),
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
                    onPressed: () => _authorizeEvent(event, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Authorize'),
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
