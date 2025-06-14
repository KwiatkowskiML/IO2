import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/repositories/user_repository.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/profile/cubit/profile_cubit.dart';
import 'package:resellio/presentation/profile/cubit/profile_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProfileCubit(context.read<UserRepository>())..loadProfile(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthService>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded && !state.isEditing) {
          // TODO: Could show a "Saved!" snackbar here after an update.
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
                  onPressed: () => context.read<ProfileCubit>().toggleEdit(true),
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
            if (state is ProfileLoading || state is ProfileInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProfileError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            if (state is ProfileLoaded || state is ProfileSaving) {
              final userProfile = (state as dynamic).userProfile;
              final isEditing =
                  state is ProfileLoaded ? state.isEditing : false;
              final isSaving = state is ProfileSaving;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ProfileHeader(userProfile: userProfile),
                    const SizedBox(height: 32),
                    _ProfileForm(
                      userProfile: userProfile,
                      isEditing: isEditing,
                      isSaving: isSaving,
                    ),
                    const SizedBox(height: 32),
                    _AccountInfo(userProfile: userProfile),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  const _ProfileHeader({required this.userProfile});

  String _getInitials() {
    final firstName = userProfile['first_name'] as String? ?? '';
    final lastName = userProfile['last_name'] as String? ?? '';
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Text('Welcome, ${userProfile['first_name']}!',
        style: Theme.of(context).textTheme.headlineMedium);
  }
}

class _ProfileForm extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final bool isEditing;
  final bool isSaving;

  const _ProfileForm(
      {required this.userProfile,
      required this.isEditing,
      required this.isSaving});

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _loginController;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.userProfile['first_name'] ?? '');
    _lastNameController =
        TextEditingController(text: widget.userProfile['last_name'] ?? '');
    _loginController =
        TextEditingController(text: widget.userProfile['login'] ?? '');
  }

  @override
  void didUpdateWidget(covariant _ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userProfile != oldWidget.userProfile) {
      _firstNameController.text = widget.userProfile['first_name'] ?? '';
      _lastNameController.text = widget.userProfile['last_name'] ?? '';
      _loginController.text = widget.userProfile['login'] ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _loginController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileCubit>().updateProfile({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'login': _loginController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _firstNameController,
            enabled: widget.isEditing,
            decoration: const InputDecoration(labelText: 'First Name'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            enabled: widget.isEditing,
            decoration: const InputDecoration(labelText: 'Last Name'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginController,
            enabled: widget.isEditing,
            decoration: const InputDecoration(labelText: 'Username'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          if (widget.isEditing) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.read<ProfileCubit>().toggleEdit(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.isSaving ? null : _save,
                    child: widget.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}

class _AccountInfo extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  const _AccountInfo({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(userProfile['email'] ?? 'N/A'),
            ),
            ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text('Status'),
              subtitle: Text(userProfile['is_active'] ? 'Active' : 'Inactive'),
            ),
          ],
        ),
      ),
    );
  }
}
