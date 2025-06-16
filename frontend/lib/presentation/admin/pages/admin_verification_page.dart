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
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/common_widgets/dialogs.dart';
import 'package:resellio/presentation/common_widgets/empty_state_widget.dart';
import 'package:resellio/presentation/common_widgets/list_item_card.dart';

class AdminVerificationPage extends StatelessWidget {
  const AdminVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        return BlocStateWrapper<AdminDashboardLoaded>(
          state: state,
          onRetry: () => context.read<AdminDashboardCubit>().loadDashboard(),
          builder: (loadedState) {
            if (loadedState.unverifiedUsers.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.verified_user_outlined,
                message: 'No unverified users',
                details: 'All users have been verified or activated.',
              );
            }

            return Column(
              children: [
                AdminCard(
                  header: AdminSectionHeader(
                    icon: Icons.verified_user,
                    title: 'User Email Verifications',
                    subtitle: '${loadedState.unverifiedUsers.length} user(s) awaiting email verification',
                  ),
                  child: const SizedBox.shrink(),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: loadedState.unverifiedUsers.length,
                    itemBuilder: (context, index) {
                      final user = loadedState.unverifiedUsers[index];
                      final isProcessing = state is UserApprovalInProgress &&
                          state.userId == user.userId;

                      return _UnverifiedUserCard(
                        user: user,
                        isProcessing: isProcessing,
                        onViewDetails: () => _showUserDetails(context, user),
                        onApprove: () => _showApprovalConfirmation(context, user),
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

  void _showUserDetails(BuildContext context, UserDetails user) {
    showDialog(
      context: context,
      builder: (context) => AdminDetailDialog(
        icon: Icons.person,
        title: '${user.firstName} ${user.lastName}',
        subtitle: 'Unverified User Details',
        sections: [
          AdminDetailSection(
            title: 'User Information',
            rows: [
              AdminDetailRow(label: 'First Name', value: user.firstName),
              AdminDetailRow(label: 'Last Name', value: user.lastName),
              AdminDetailRow(label: 'Email', value: user.email),
              AdminDetailRow(label: 'User Type', value: user.userType.toUpperCase()),
              AdminDetailRow(label: 'User ID', value: user.userId.toString()),
            ],
          ),
          AdminDetailSection(
            title: 'Account Status',
            rows: [
              AdminDetailRow(label: 'Active Status', value: user.isActive ? 'Active' : 'Inactive'),
              AdminDetailRow(label: 'Verification Status', value: 'Email Not Verified'),
              AdminDetailRow(label: 'Registration Status', value: 'Pending Activation'),
            ],
          ),
        ],
        footer: _buildVerificationFooter(),
      ),
    );
  }

  Widget _buildVerificationFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This user has not verified their email address. You can manually approve them to bypass email verification and activate their account.',
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

  void _showApprovalConfirmation(
      BuildContext context,
      UserDetails user,
      ) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Approve User Account',
      content: Text(
        'Are you sure you want to manually approve ${user.firstName} ${user.lastName}?\n\n'
            'This will:\n'
            '• Activate their account immediately\n'
            '• Bypass email verification requirement\n'
            '• Allow them to log in normally\n\n'
            'Email: ${user.email}',
      ),
      confirmText: 'Approve Account',
      isDestructive: false,
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<AdminDashboardCubit>().approveUser(user.userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${user.firstName} ${user.lastName} has been approved'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _UnverifiedUserCard extends StatelessWidget {
  final UserDetails user;
  final bool isProcessing;
  final VoidCallback onViewDetails;
  final VoidCallback onApprove;

  const _UnverifiedUserCard({
    required this.user,
    required this.isProcessing,
    required this.onViewDetails,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userTypeColor = _getUserTypeColor(user.userType);

    return ListItemCard(
      isProcessing: isProcessing,
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
          AdminInfoRow(
            icon: Icons.email,
            text: user.email,
          ),
          const SizedBox(height: 2),
          AdminInfoRow(
            icon: Icons.person,
            text: user.userType.toUpperCase(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const AdminStatusChip(
                  type: AdminStatusType.pending,
                  customText: 'EMAIL NOT VERIFIED'
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pending, size: 12, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'AWAITING ACTIVATION',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomContent: AdminActionButtons(
        isProcessing: isProcessing,
        actions: [
          AdminAction.secondary(
            label: 'View Details',
            icon: Icons.info_outline,
            onPressed: onViewDetails,
          ),
          AdminAction.primary(
            label: 'Approve User',
            icon: Icons.check_circle,
            onPressed: onApprove,
          ),
        ],
      ),
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'administrator':
      case 'admin':
        return Colors.purple;
      case 'organizer':
        return Colors.blue;
      case 'customer':
      default:
        return Colors.green;
    }
  }
}