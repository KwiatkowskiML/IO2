import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/presentation/common_widgets/custom_text_form_field.dart';

// Read-only ticket type display
class TicketTypeForm extends StatelessWidget {
  final TicketType ticketType;
  final int index;
  final VoidCallback? onDelete;
  final bool isDeletable;

  const TicketTypeForm({
    super.key,
    required this.ticketType,
    required this.index,
    this.onDelete,
    this.isDeletable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine the display status
    final isActive = ticketType.availableFrom?.isAfter(DateTime.now()) ?? false;
    final statusColor = isActive ? Colors.green : Colors.orange;
    final statusText = isActive ? 'Not yet available' : 'Sales active';

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticketType.description ?? 'Unnamed Ticket Type',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        statusText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isDeletable && onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: colorScheme.error,
                  ),
                  tooltip: 'Remove ticket type',
                )
              else if (!isDeletable)
                Tooltip(
                  message: 'Cannot delete - tickets may have been sold',
                  child: Icon(
                    Icons.lock_outline,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Display ticket type details (read-only)
          _buildInfoRow(
            context,
            'Count:',
            '${ticketType.maxCount} tickets',
            Icons.confirmation_number_outlined,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            'Price:',
            '${ticketType.currency} \$${ticketType.price.toStringAsFixed(2)}',
            Icons.attach_money,
          ),
          const SizedBox(height: 8),
          if (ticketType.availableFrom != null)
            _buildInfoRow(
              context,
              'Available from:',
              DateFormat.yMd().add_jm().format(ticketType.availableFrom!),
              Icons.schedule,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

// Editable version for creating new ticket types
class EditableTicketTypeForm extends StatefulWidget {
  final TicketType ticketType;
  final int index;
  final Function(TicketType) onChanged;
  final VoidCallback onDelete;

  const EditableTicketTypeForm({
    super.key,
    required this.ticketType,
    required this.index,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<EditableTicketTypeForm> createState() => _EditableTicketTypeFormState();
}

class _EditableTicketTypeFormState extends State<EditableTicketTypeForm> {
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

    widget.onChanged(widget.ticketType.copyWith(
      description: description,
      maxCount: maxCount,
      price: price,
      currency: 'USD',
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

    widget.onChanged(widget.ticketType.copyWith(availableFrom: selectedDateTime));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Ticket Type',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
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
