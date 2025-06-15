import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/common_widgets/custom_text_form_field.dart';
import 'package:resellio/presentation/common_widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  final String userType;
  const RegisterScreen({super.key, required this.userType});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  // Text Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _loginController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _loginController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authService = context.read<AuthService>();
      final data = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'login': _loginController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
      };

      try {
        if (widget.userType == 'organizer') {
          data['company_name'] = _companyNameController.text;
          await authService.registerOrganizer(data);
        } else {
          await authService.registerCustomer(data);
        }
        // On success, the router will redirect automatically
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOrganizer = widget.userType == 'organizer';

    return Scaffold(
      appBar: AppBar(
        title: Text(isOrganizer ? 'Organizer Signup' : 'Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Join Resellio',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create an account to start buying and selling.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  CustomTextFormField(
                    controller: _firstNameController,
                    labelText: 'First Name',
                    validator:
                        (v) => v!.isEmpty ? 'First Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: _lastNameController,
                    labelText: 'Last Name',
                    validator:
                        (v) => v!.isEmpty ? 'Last Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: _loginController,
                    labelText: 'Username/Login',
                    validator:
                        (v) => v!.isEmpty ? 'Username is required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: _emailController,
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty || !v.contains('@')
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: _passwordController,
                    labelText: 'Password',
                    obscureText: true,
                    validator: (v) =>
                        v!.length < 8 ? 'Password must be 8+ characters' : null,
                  ),
                  if (isOrganizer) ...[
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      controller: _companyNameController,
                      labelText: 'Company Name',
                      validator:
                          (v) => v!.isEmpty ? 'Company Name is required' : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  PrimaryButton(
                    text: 'REGISTER',
                    onPressed: _register,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    child: Text(
                      'Already have an account? Log In',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
