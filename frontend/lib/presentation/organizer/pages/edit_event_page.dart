import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/common_widgets/custom_text_form_field.dart';
import 'package:resellio/presentation/common_widgets/primary_button.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/organizer/cubit/event_form_cubit.dart';
import 'package:resellio/presentation/organizer/cubit/event_form_state.dart';

class EditEventPage extends StatelessWidget {
  final Event event;
  const EditEventPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EventFormCubit(context.read<EventRepository>()),
      child: _EditEventView(event: event),
    );
  }
}

class _EditEventView extends StatefulWidget {
  final Event event;
  const _EditEventView({required this.event});

  @override
  State<_EditEventView> createState() => _EditEventViewState();
}

class _EditEventViewState extends State<_EditEventView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minimumAgeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.event.name;
    _descriptionController.text = widget.event.description ?? '';
    _minimumAgeController.text = widget.event.minimumAge?.toString() ?? '';
    _startDate = widget.event.start;
    _endDate = widget.event.end;
    _startDateController.text = DateFormat.yMd().add_jm().format(_startDate!);
    _endDateController.text = DateFormat.yMd().add_jm().format(_endDate!);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minimumAgeController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (time == null) return;

    final selectedDateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      if (isStart) {
        _startDate = selectedDateTime;
        _startDateController.text =
            DateFormat.yMd().add_jm().format(selectedDateTime);
      } else {
        _endDate = selectedDateTime;
        _endDateController.text =
            DateFormat.yMd().add_jm().format(selectedDateTime);
      }
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final eventData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'minimum_age': int.tryParse(_minimumAgeController.text),
      };
      context
          .read<EventFormCubit>()
          .updateEvent(widget.event.id, eventData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Edit Event',
      showBackButton: true,
      showCartButton: false,
      body: BlocListener<EventFormCubit, EventFormState>(
        listener: (context, state) {
          if (state is EventFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Event updated successfully!'),
                  backgroundColor: Colors.green),
            );
            context.go('/home/organizer');
          }
          if (state is EventFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextFormField(
                  controller: _nameController,
                  labelText: 'Event Name',
                  validator: (v) =>
                      v!.isEmpty ? 'Event name is required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _startDateController,
                  labelText: 'Start Date & Time',
                  readOnly: true,
                  onTap: () => _selectDateTime(context, true),
                  validator: (v) =>
                      v!.isEmpty ? 'Start date is required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _endDateController,
                  labelText: 'End Date & Time',
                  readOnly: true,
                  onTap: () => _selectDateTime(context, false),
                  validator: (v) => v!.isEmpty ? 'End date is required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _minimumAgeController,
                  labelText: 'Minimum Age (Optional)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),
                BlocBuilder<EventFormCubit, EventFormState>(
                  builder: (context, state) {
                    return PrimaryButton(
                      text: 'SAVE CHANGES',
                      onPressed: _submitForm,
                      isLoading: state is EventFormSubmitting,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
