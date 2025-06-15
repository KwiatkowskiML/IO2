import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_cubit.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_state.dart';
import 'package:resellio/presentation/admin/widgets/admin_card.dart';
import 'package:resellio/presentation/admin/widgets/admin_section_header.dart';
import 'package:resellio/presentation/common_widgets/custom_text_form_field.dart';
import 'package:resellio/presentation/common_widgets/primary_button.dart';

class AdminRegistrationPage extends StatefulWidget {
  const AdminRegistrationPage({super.key});

  @override
  State<AdminRegistrationPage> createState() => _AdminRegistrationPageState();
}

class _AdminRegistrationPageState extends State<AdminRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _loginController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adminSecretController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _loginController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adminSecretController.dispose();
    super.dispose();
  }

  Future<void> _registerAdmin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      final adminData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'login': _loginController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'admin_secret_key': _adminSecretController.text,
      };

      try {
        await context.read<AdminDashboardCubit>().registerAdmin(adminData);
        if (mounted) {
          setState(() {
            _isLoading = false;
            _successMessage = 'Administrator account created successfully!';
          });
          _clearForm();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
          });
        }
      }
    }
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _loginController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _adminSecretController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AdminDashboardCubit, AdminDashboardState>(
      listener: (context, state) {
        if (state is AdminDashboardError) {
          setState(() {
            _isLoading = false;
            _errorMessage = state.message;
            _successMessage = null;
          });
        } else if (state is AdminDashboardLoaded) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _HeaderCard(),
            const SizedBox(height: 24),
            _SecurityNoticeCard(),
            const SizedBox(height: 24),
            _RegistrationFormCard(
              formKey: _formKey,
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              loginController: _loginController,
              emailController: _emailController,
              passwordController: _passwordController,
              confirmPasswordController: _confirmPasswordController,
              adminSecretController: _adminSecretController,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              successMessage: _successMessage,
              onRegister: _registerAdmin,
              onClear: _clearForm,
            ),
            const SizedBox(height: 24),
            _PrivilegesInfoCard(),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AdminCard(
      backgroundColor: colorScheme.primaryContainer,
      child: AdminSectionHeader(
        icon: Icons.admin_panel_settings,
        title: 'Register New Administrator',
        subtitle: 'Create a new admin account with full system privileges',
        iconColor: colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _SecurityNoticeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminCard(
      backgroundColor: Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Notice',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Administrator accounts have full system access. Only create accounts for trusted personnel.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController loginController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController adminSecretController;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final VoidCallback onRegister;
  final VoidCallback onClear;

  const _RegistrationFormCard({
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.loginController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.adminSecretController,
    required this.isLoading,
    required this.errorMessage,
    required this.successMessage,
    required this.onRegister,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminCard(
      header: Text(
        'Administrator Details',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PersonalInfoSection(
              firstNameController: firstNameController,
              lastNameController: lastNameController,
            ),
            const SizedBox(height: 16),
            _AccountInfoSection(
              loginController: loginController,
              emailController: emailController,
            ),
            const SizedBox(height: 16),
            _PasswordSection(
              passwordController: passwordController,
              confirmPasswordController: confirmPasswordController,
            ),
            const SizedBox(height: 24),
            _AdminSecretSection(
              adminSecretController: adminSecretController,
            ),
            const SizedBox(height: 24),
            _MessageSection(
              successMessage: successMessage,
              errorMessage: errorMessage,
            ),
            _ActionButtons(
              isLoading: isLoading,
              onRegister: onRegister,
              onClear: onClear,
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalInfoSection extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;

  const _PersonalInfoSection({
    required this.firstNameController,
    required this.lastNameController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomTextFormField(
            controller: firstNameController,
            labelText: 'First Name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'First name is required';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomTextFormField(
            controller: lastNameController,
            labelText: 'Last Name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Last name is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class _AccountInfoSection extends StatelessWidget {
  final TextEditingController loginController;
  final TextEditingController emailController;

  const _AccountInfoSection({
    required this.loginController,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextFormField(
          controller: loginController,
          labelText: 'Username/Login',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Username is required';
            }
            if (value.length < 3) {
              return 'Username must be at least 3 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          controller: emailController,
          labelText: 'Email Address',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _PasswordSection extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const _PasswordSection({
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextFormField(
          controller: passwordController,
          labelText: 'Password',
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            if (!value.contains(RegExp(r'[A-Z]'))) {
              return 'Password must contain at least one uppercase letter';
            }
            if (!value.contains(RegExp(r'[0-9]'))) {
              return 'Password must contain at least one number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          controller: confirmPasswordController,
          labelText: 'Confirm Password',
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _AdminSecretSection extends StatelessWidget {
  final TextEditingController adminSecretController;

  const _AdminSecretSection({
    required this.adminSecretController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Admin Secret Key Required',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the admin secret key to authorize creation of a new administrator account.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
          CustomTextFormField(
            controller: adminSecretController,
            labelText: 'Admin Secret Key',
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Admin secret key is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _MessageSection extends StatelessWidget {
  final String? successMessage;
  final String? errorMessage;

  const _MessageSection({
    this.successMessage,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (successMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    successMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRegister;
  final VoidCallback onClear;

  const _ActionButtons({
    required this.isLoading,
    required this.onRegister,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : onClear,
            child: const Text('Clear Form'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: PrimaryButton(
            text: 'CREATE ADMINISTRATOR',
            onPressed: isLoading ? null : onRegister,
            isLoading: isLoading,
            icon: Icons.admin_panel_settings,
          ),
        ),
      ],
    );
  }
}

class _PrivilegesInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Administrator Privileges',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'New administrators will have access to:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PrivilegeItem(text: 'User management and account controls'),
              _PrivilegeItem(text: 'Organizer verification and approval'),
              _PrivilegeItem(text: 'Event authorization and moderation'),
              _PrivilegeItem(text: 'System administration features'),
              _PrivilegeItem(text: 'Creating additional admin accounts'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrivilegeItem extends StatelessWidget {
  final String text;

  const _PrivilegeItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            Icons.check,
            color: colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}