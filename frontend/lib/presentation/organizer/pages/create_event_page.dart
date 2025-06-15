import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
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
      create: (context) => EventFormCubit(context.read<EventRepository>())
        ..loadPrerequisites(),
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
  final _minimumAgeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedLocationId;
  final List<String> _selectedCategories = [];

  final List<String> _availableCategories = [
    'Music', 'Sports', 'Arts', 'Food', 'Technology', 'Festival', 'Conference'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _totalTicketsController.dispose();
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
      if (_startDate == null || _endDate == null || _selectedLocationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      final eventData = EventCreate(
        name: _nameController.text,
        description: _descriptionController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        locationId: _selectedLocationId!,
        category: _selectedCategories,
        totalTickets: int.parse(_totalTicketsController.text),
        minimumAge: int.tryParse(_minimumAgeController.text),
      );
      context.read<EventFormCubit>().createEvent(eventData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Create New Event',
      showBackButton: true,
      showCartButton: false,
      body: BlocConsumer<EventFormCubit, EventFormState>(
        listener: (context, state) {
          if (state is EventFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Event created successfully! Awaiting authorization.'),
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
        builder: (context, state) {
          return BlocStateWrapper<EventFormPrerequisitesLoaded>(
            state: state,
            onRetry: () =>
                context.read<EventFormCubit>().loadPrerequisites(),
            builder: (loadedState) {
              return SingleChildScrollView(
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
                      DropdownButtonFormField<int>(
                        value: _selectedLocationId,
                        onChanged: (value) {
                          setState(() => _selectedLocationId = value);
                        },
                        items: loadedState.locations.map((location) {
                          return DropdownMenuItem<int>(
                            value: location.locationId,
                            child: Text(location.name),
                          );
                        }).toList(),
                        decoration: const InputDecoration(labelText: 'Location'),
                        validator: (v) =>
                            v == null ? 'Location is required' : null,
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
                        validator: (v) =>
                            v!.isEmpty ? 'End date is required' : null,
                      ),
                      const SizedBox(height: 24),
                      Text('Categories', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: _availableCategories.map((category) {
                          final isSelected = _selectedCategories.contains(category);
                          return ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      CustomTextFormField(
                        controller: _descriptionController,
                        labelText: 'Description',
                        keyboardType: TextInputType.multiline,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextFormField(
                              controller: _totalTicketsController,
                              labelText: 'Total Tickets',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v!.isEmpty) return 'Total tickets is required';
                                if (int.tryParse(v) == null || int.parse(v) <= 0) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextFormField(
                              controller: _minimumAgeController,
                              labelText: 'Minimum Age (Optional)',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        text: 'CREATE EVENT',
                        onPressed: _submitForm,
                        isLoading: state is EventFormSubmitting,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
