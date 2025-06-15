import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_cubit.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_state.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/common_widgets/list_item_card.dart';
import 'package:resellio/presentation/common_widgets/dialogs.dart';
import 'package:resellio/presentation/common_widgets/empty_state_widget.dart';

class AdminOrganizersPage extends StatelessWidget {
  const AdminOrganizersPage({super.key});

  void _showOrganizerDetails(BuildContext context, PendingOrganizer organizer) {
    showDialog(
      context: context,
      builder: (context) => _OrganizerDetailsDialog(organizer: organizer),
    );
  }

  void _showVerificationConfirmation(
      BuildContext context,
      PendingOrganizer organizer,
      bool approve,
      ) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: approve ? 'Approve Organizer' : 'Reject Organizer',
      content: Text(
        approve
            ? 'Are you sure you want to approve ${organizer.firstName} ${organizer.lastName} from ${organizer.companyName}?\n\n'
            'This will grant them organizer privileges and allow them to create events.'
            : 'Are you sure you want to reject ${organizer.firstName} ${organizer.lastName} from ${organizer.companyName}?\n\n'
            'This will prevent them from accessing organizer features.',
      ),
      confirmText: approve ? 'Approve' : 'Reject',
      isDestructive: !approve,
    );

    if (confirmed == true && context.mounted) {
      context.read<AdminDashboardCubit>().verifyOrganizer(organizer.organizerId, approve);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        return BlocStateWrapper<AdminDashboardLoaded>(
          state: state,
          onRetry: () => context.read<AdminDashboardCubit>().loadDashboard(),
          builder: (loadedState) {
            if (loadedState.pendingOrganizers.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.verified_user_outlined,
                message: 'No pending organizers',
                details: 'All organizer applications have been processed.',
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pending Organizer Verifications',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${loadedState.pendingOrganizers.length} organizer(s) awaiting verification',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Organizers List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: loadedState.pendingOrganizers.length,
                    itemBuilder: (context, index) {
                      final organizer = loadedState.pendingOrganizers[index];
                      final isProcessing = state is AdminDashboardLoading;

                      return _PendingOrganizerCard(
                        organizer: organizer,
                        isProcessing: isProcessing,
                        onViewDetails: () => _showOrganizerDetails(context, organizer),
                        onApprove: () => _showVerificationConfirmation(context, organizer, true),
                        onReject: () => _showVerificationConfirmation(context, organizer, false),
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
}

class _PendingOrganizerCard extends StatelessWidget {
  final PendingOrganizer organizer;
  final bool isProcessing;
  final VoidCallback onViewDetails;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingOrganizerCard({
    required this.organizer,
    required this.isProcessing,
    required this.onViewDetails,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListItemCard(
      isProcessing: isProcessing,
      leadingWidget: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            '${organizer.firstName[0]}${organizer.lastName[0]}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text('${organizer.firstName} ${organizer.lastName}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.business,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  organizer.companyName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.email,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  organizer.email,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'PENDING VERIFICATION',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      bottomContent: Column(
        children: [
          // Company Information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildInfoItem(
                  context,
                  Icons.badge,
                  'User ID: ${organizer.userId}',
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  context,
                  Icons.business_center,
                  'Org ID: ${organizer.organizerId}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: isProcessing ? null : onViewDetails,
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('View Details'),
              ),
              TextButton.icon(
                onPressed: isProcessing ? null : onReject,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Reject'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
              ElevatedButton.icon(
                onPressed: isProcessing ? null : onApprove,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _OrganizerDetailsDialog extends StatelessWidget {
  final PendingOrganizer organizer;

  const _OrganizerDetailsDialog({required this.organizer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.business,
              color: colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${organizer.firstName} ${organizer.lastName}',
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  'Organizer Application',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSection(
              context,
              'Personal Information',
              [
                _buildDetailRow('First Name', organizer.firstName),
                _buildDetailRow('Last Name', organizer.lastName),
                _buildDetailRow('Email', organizer.email),
                _buildDetailRow('User ID', organizer.userId.toString()),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              'Company Information',
              [
                _buildDetailRow('Company Name', organizer.companyName),
                _buildDetailRow('Organizer ID', organizer.organizerId.toString()),
                _buildDetailRow('Verification Status', organizer.isVerified ? 'Verified' : 'Pending'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please review the organizer\'s information carefully before making a decision. Approved organizers will be able to create and manage events.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}