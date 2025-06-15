import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/presentation/common_widgets/custom_text_form_field.dart';
import 'package:resellio/presentation/profile/cubit/profile_cubit.dart';

class ProfileForm extends StatefulWidget {
  final UserProfile userProfile;
  final bool isEditing;
  final bool isSaving;

  const ProfileForm(
      {super.key,
      required this.userProfile,
      required this.isEditing,
      required this.isSaving});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _loginController;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.userProfile.firstName);
    _lastNameController =
        TextEditingController(text: widget.userProfile.lastName);
    _loginController = TextEditingController(text: widget.userProfile.login ?? '');
  }

  @override
  void didUpdateWidget(covariant ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userProfile != oldWidget.userProfile) {
      _firstNameController.text = widget.userProfile.firstName;
      _lastNameController.text = widget.userProfile.lastName;
      _loginController.text = widget.userProfile.login ?? '';
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
          CustomTextFormField(
            controller: _firstNameController,
            enabled: widget.isEditing,
            labelText: 'First Name',
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: _lastNameController,
            enabled: widget.isEditing,
            labelText: 'Last Name',
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: _loginController,
            enabled: widget.isEditing,
            labelText: 'Username',
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          if (widget.isEditing) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        context.read<ProfileCubit>().toggleEdit(false),
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
