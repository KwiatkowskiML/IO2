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
import 'package:resellio/presentation/organizer/widgets/ticket_type_form.dart';

class EditEventPage extends StatelessWidget {
  final Event event;
  const EditEventPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EventFormCubit(context.read<EventRepository>())
        ..loadExistingTicketTypes(event.id),
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

  // FIXED: Changed from TicketTypeData to TicketType
  List<TicketType> _additionalTicketTypes = [];

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

  void _addTicketType() {
    setState(() {
      _additionalTicketTypes.add(TicketType(
        eventId: widget.event.id,
        description: '',
        maxCount: 0,
        price: 0.0,
        currency: 'USD',
        availableFrom: DateTime.now().add(Duration(hours: 1)),
      ));
    });
  }

  void _removeTicketType(int index) {
    setState(() {
      _additionalTicketTypes.removeAt(index);
    });
  }

  void _updateTicketType(int index, TicketType ticketType) {
    setState(() {
      _additionalTicketTypes[index] = ticketType;
    });
  }

  bool _validateTicketTypes() {
    for (int i = 0; i < _additionalTicketTypes.length; i++) {
      final ticketType = _additionalTicketTypes[i];

      if ((ticketType.description ?? '').isEmpty) {
        _showError('Please fill description for ticket type ${i + 1}.');
        return false;
      }
      if (ticketType.maxCount <= 0) {
        _showError('Please enter valid ticket count for ticket type ${i + 1}.');
        return false;
      }
      if (ticketType.price < 0) {
        _showError('Please enter valid price for ticket type ${i + 1}.');
        return false;
      }
      if (ticketType.availableFrom == null) {
        _showError('Please set available from date for ticket type ${i + 1}.');
        return false;
      }
      if (ticketType.availableFrom!.isAfter(_startDate!)) {
        _showError('Available from date for ticket type ${i + 1} cannot be after event start date.');
        return false;
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _validateTicketTypes()) {
      final eventData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'minimum_age': int.tryParse(_minimumAgeController.text),
      };

      context
          .read<EventFormCubit>()
          .updateEventWithTicketTypes(widget.event.id, eventData, _additionalTicketTypes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          if (state is EventFormTicketTypesLoaded) {
            setState(() {
              _additionalTicketTypes = state.ticketTypes
                  .where((t) => (t.description ?? '') != "Standard Ticket")
                  .toList();
            });
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEventDetailsSection(theme),
                const SizedBox(height: 32),

                _buildTicketTypesSection(theme),
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

  Widget _buildEventDetailsSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Event Details", style: theme.textTheme.headlineSmall),
            const SizedBox(height: 20),
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
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextFormField(
                    controller: _startDateController,
                    labelText: 'Start Date & Time',
                    readOnly: true,
                    onTap: () => _selectDateTime(context, true),
                    validator: (v) => v!.isEmpty ? 'Start date is required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextFormField(
                    controller: _endDateController,
                    labelText: 'End Date & Time',
                    readOnly: true,
                    onTap: () => _selectDateTime(context, false),
                    validator: (v) => v!.isEmpty ? 'End date is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextFormField(
              controller: _minimumAgeController,
              labelText: 'Minimum Age (Optional)',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTypesSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Additional Ticket Types", style: theme.textTheme.headlineSmall),
                OutlinedButton.icon(
                  onPressed: _addTicketType,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Type'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Add different ticket types with varying prices (VIP, Early Bird, etc.)",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (_additionalTicketTypes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No additional ticket types yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Standard tickets are already available. Add premium types here.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _additionalTicketTypes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TicketTypeForm(
                      ticketType: _additionalTicketTypes[index],
                      index: index + 2,
                      onChanged: (ticketType) => _updateTicketType(index, ticketType),
                      onDelete: () => _removeTicketType(index),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
