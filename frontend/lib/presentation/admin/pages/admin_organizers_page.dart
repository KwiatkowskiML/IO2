import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_cubit.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_state.dart';
import 'package:resellio/presentation/admin/widgets/admin_card.dart';
import 'package:resellio/presentation/admin/widgets/admin_section_header.dart';
import 'package:resellio/presentation/admin/widgets/admin_action_buttons.dart';
import 'package:resellio/presentation/admin/widgets/admin_status_chip.dart';
import 'package:resellio/presentation/admin/widgets/admin_info_row.dart';
import 'package:resellio/presentation/admin/widgets/admin_detail_dialog.dart';
import 'package:resellio/presentation/admin/widgets/admin_stats_container.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/common_widgets/dialogs.dart';
import 'package:resellio/presentation/common_widgets/empty_state_widget.dart';
import 'package:resellio/presentation/common_widgets/list_item_card.dart';

class AdminOrganizersPage extends StatelessWidget {
  const AdminOrganizersPage({super.key});

  @override
  Widget build(BuildContext context) {
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
              children: [
                AdminCard(
                  header: AdminSectionHeader(
                    icon: Icons.business,
                    title: 'Pending Organizer Verifications',
                    subtitle: '${loadedState.pendingOrganizers.length} organizer(s) awaiting verification',
                  ),
                  child: const SizedBox.shrink(),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: loadedState.pendingOrganizers.length,
                    itemBuilder: (context, index) {
                      final organizer = loadedState.pendingOrganizers[index];
                      final isProcessing = state is AdminDashboardLoading;

                      return _OrganizerCard(
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

  void _showOrganizerDetails(BuildContext context, PendingOrganizer organizer) {
    showDialog(
      context: context,
      builder: (context) => AdminDetailDialog(
        icon: Icons.business,
        title: '${organizer.firstName} ${organizer.lastName}',
        subtitle: 'Organizer Application',
        sections: [
          AdminDetailSection(
            title: 'Personal Information',
            rows: [
              AdminDetailRow(label: 'First Name', value: organizer.firstName),
              AdminDetailRow(label: 'Last Name', value: organizer.lastName),
              AdminDetailRow(label: 'Email', value: organizer.email),
              AdminDetailRow(label: 'User ID', value: organizer.userId.toString()),
            ],
          ),
          AdminDetailSection(
            title: 'Company Information',
            rows: [
              AdminDetailRow(label: 'Company Name', value: organizer.companyName),
              AdminDetailRow(label: 'Organizer ID', value: organizer.organizerId.toString()),
              AdminDetailRow(label: 'Verification Status', value: organizer.isVerified ? 'Verified' : 'Pending'),
            ],
          ),
        ],
        footer: _buildInfoFooter(),
      ),
    );
  }

  Widget _buildInfoFooter() {
    return Container(
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
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
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
}

class _OrganizerCard extends StatelessWidget {
  final PendingOrganizer organizer;
  final bool isProcessing;
  final VoidCallback onViewDetails;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _OrganizerCard({
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
      leadingWidget: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          '${organizer.firstName[0]}${organizer.lastName[0]}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text('${organizer.firstName} ${organizer.lastName}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          AdminInfoRow(
            icon: Icons.business,
            text: organizer.companyName,
          ),
          const SizedBox(height: 2),
          AdminInfoRow(
            icon: Icons.email,
            text: organizer.email,
          ),
          const SizedBox(height: 8),
          const AdminStatusChip(type: AdminStatusType.pending, customText: 'PENDING VERIFICATION'),
        ],
      ),
      bottomContent: Column(
        children: [
          AdminStatsContainer(
            stats: [
              AdminStatItem(
                icon: Icons.badge,
                text: 'User ID: ${organizer.userId}',
              ),
              AdminStatItem(
                icon: Icons.business_center,
                text: 'Org ID: ${organizer.organizerId}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdminActionButtons(
            isProcessing: isProcessing,
            actions: [
              AdminAction.secondary(
                label: 'View Details',
                icon: Icons.info_outline,
                onPressed: onViewDetails,
              ),
              AdminAction.destructive(
                label: 'Reject',
                icon: Icons.close,
                onPressed: onReject,
              ),
              AdminAction.primary(
                label: 'Approve',
                icon: Icons.check,
                onPressed: onApprove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}