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

class CreateEventPage extends StatelessWidget {
  const CreateEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EventFormCubit(context.read<EventRepository>()),
      child: const _CreateEventView(),
    );
  }
}

class _CreateEventView extends StatefulWidget {
  const _CreateEventView();

  @override
  State<_CreateEventView> createState() => _CreateEventViewState();
}

class _CreateEventViewState extends State<_CreateEventView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalTicketsController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _totalTicketsController.dispose();
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
      final eventData = EventCreate(
        name: _nameController.text,
        description: _descriptionController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        locationId: 1, // Hardcoded for now
        category: ['Music', 'Concert'], // Hardcoded for now
        totalTickets: int.parse(_totalTicketsController.text),
      );
      context.read<EventFormCubit>().createEvent(eventData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Create New Event',
      showBackButton: true,
      body: BlocListener<EventFormCubit, EventFormState>(
        listener: (context, state) {
          if (state is EventFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Event created successfully!'),
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
                  validator: (v) => v!.isEmpty ? 'Event name is required' : null,
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
                  validator: (v) => v!.isEmpty ? 'Start date is required' : null,
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
                  controller: _totalTicketsController,
                  labelText: 'Total Tickets',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return 'Total tickets is required';
                    if (int.tryParse(v) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                BlocBuilder<EventFormCubit, EventFormState>(
                  builder: (context, state) {
                    return PrimaryButton(
                      text: 'CREATE EVENT',
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
