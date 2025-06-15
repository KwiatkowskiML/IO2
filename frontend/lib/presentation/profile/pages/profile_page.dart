import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/common_widgets/dialogs.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/profile/cubit/profile_cubit.dart';
import 'package:resellio/presentation/profile/cubit/profile_state.dart';
import 'package:resellio/presentation/profile/widgets/account_info.dart';
import 'package:resellio/presentation/profile/widgets/profile_form.dart';
import 'package:resellio/presentation/profile/widgets/profile_header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(
        context.read<UserRepository>(),
        context.read<AuthService>(),
      )..loadProfile(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  void _showLogoutDialog(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Logout',
      content: const Text('Are you sure you want to logout?'),
      confirmText: 'Logout',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthService>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded && !state.isEditing) {
          // Could show a "Saved!" snackbar here after an update.
        }
      },
      child: PageLayout(
        title: 'Profile',
        actions: [
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoaded && !state.isEditing) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      context.read<ProfileCubit>().toggleEdit(true),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            return BlocStateWrapper<ProfileLoaded>(
              state: state,
              onRetry: () => context.read<ProfileCubit>().loadProfile(),
              builder: (loadedState) {
                final userProfile = loadedState.userProfile;
                final isEditing = loadedState.isEditing;
                final isSaving = loadedState is ProfileSaving;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ProfileHeader(userProfile: userProfile),
                      const SizedBox(height: 32),
                      ProfileForm(
                        userProfile: userProfile,
                        isEditing: isEditing,
                        isSaving: isSaving,
                      ),
                      const SizedBox(height: 32),
                      AccountInfo(userProfile: userProfile),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
