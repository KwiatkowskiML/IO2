import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resellio/presentation/common_widgets/custom_text_form_field.dart';
import 'package:resellio/core/models/models.dart';

class TicketTypeForm extends StatefulWidget {
  final TicketType ticketType;
  final int index;
  final Function(TicketType) onChanged;
  final VoidCallback onDelete;

  const TicketTypeForm({
    super.key,
    required this.ticketType,
    required this.index,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<TicketTypeForm> createState() => _TicketTypeFormState();
}

class _TicketTypeFormState extends State<TicketTypeForm> {
  late TextEditingController _descriptionController;
  late TextEditingController _maxCountController;
  late TextEditingController _priceController;
  late TextEditingController _availableFromController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.ticketType.description ?? '');
    _maxCountController = TextEditingController(text: widget.ticketType.maxCount.toString());
    _priceController = TextEditingController(text: widget.ticketType.price.toString());
    _availableFromController = TextEditingController(
      text: widget.ticketType.availableFrom != null
        ? DateFormat.yMd().add_jm().format(widget.ticketType.availableFrom!)
        : ''
    );

    _descriptionController.addListener(_updateTicketType);
    _maxCountController.addListener(_updateTicketType);
    _priceController.addListener(_updateTicketType);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _maxCountController.dispose();
    _priceController.dispose();
    _availableFromController.dispose();
    super.dispose();
  }

  void _updateTicketType() {
    final description = _descriptionController.text;
    final maxCount = int.tryParse(_maxCountController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    // Use copyWith method from the unified model
    widget.onChanged(widget.ticketType.copyWith(
      description: description,
      maxCount: maxCount,
      price: price,
      currency: 'USD',
      // Preserve the existing availableFrom date
    ));
  }

  Future<void> _selectAvailableFromDateTime(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: widget.ticketType.availableFrom ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.ticketType.availableFrom ?? DateTime.now()),
    );
    if (time == null) return;

    final selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      _availableFromController.text = DateFormat.yMd().add_jm().format(selectedDateTime);
    });

    // Update the ticket type with the new date using copyWith
    widget.onChanged(widget.ticketType.copyWith(availableFrom: selectedDateTime));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ticket Type ${widget.index}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                ),
                tooltip: 'Remove ticket type',
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: _descriptionController,
            labelText: 'Description (e.g., VIP, Early Bird)',
            validator: (v) => v!.isEmpty ? 'Description is required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                  controller: _maxCountController,
                  labelText: 'Ticket Count',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return 'Count is required';
                    if (int.tryParse(v) == null || int.parse(v) <= 0) {
                      return 'Enter valid count';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextFormField(
                  controller: _priceController,
                  labelText: 'Price (\$)',
                  prefixText: '\$ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v!.isEmpty) return 'Price is required';
                    if (double.tryParse(v) == null || double.parse(v) < 0) {
                      return 'Enter valid price';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: _availableFromController,
            labelText: 'Available From Date & Time *',
            readOnly: true,
            onTap: () => _selectAvailableFromDateTime(context),
            validator: (v) => v!.isEmpty ? 'Available from date is required' : null,
          ),
        ],
      ),
    );
  }
}
