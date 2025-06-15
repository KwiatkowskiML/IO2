import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/event_filter_model.dart';
import 'package:resellio/presentation/common_widgets/custom_text_form_field.dart';
import 'package:resellio/presentation/common_widgets/primary_button.dart';

class EventFilterSheet extends StatefulWidget {
  final EventFilterModel initialFilters;
  final Function(EventFilterModel) onApplyFilters;
  final bool showAdvancedFilters;

  const EventFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onApplyFilters,
    this.showAdvancedFilters = true,
  });

  @override
  State<EventFilterSheet> createState() => _EventFilterSheetState();
}

class _EventFilterSheetState extends State<EventFilterSheet> {
  late EventFilterModel _currentFilters;
  final _locationController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
    _locationController.text = _currentFilters.location ?? '';
    _minPriceController.text = _currentFilters.minPrice?.toString() ?? '';
    _maxPriceController.text = _currentFilters.maxPrice?.toString() ?? '';
    _startDate = _currentFilters.startDateFrom;
    _endDate = _currentFilters.startDateTo;

    if (_startDate != null) {
      _startDateController.text = DateFormat('MMM d, yyyy').format(_startDate!);
    }
    if (_endDate != null) {
      _endDateController.text = DateFormat('MMM d, yyyy').format(_endDate!);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('MMM d, yyyy').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('MMM d, yyyy').format(picked);
        }
      });
    }
  }

  void _apply() {
    final newFilters = EventFilterModel(
      location: _locationController.text.isEmpty ? null : _locationController.text,
      startDateFrom: _startDate,
      startDateTo: _endDate,
      minPrice: double.tryParse(_minPriceController.text),
      maxPrice: double.tryParse(_maxPriceController.text),
    );
    widget.onApplyFilters(newFilters);
    Navigator.pop(context);
  }

  void _clear() {
    setState(() {
      _currentFilters = const EventFilterModel();
      _locationController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _startDateController.clear();
      _endDateController.clear();
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tune,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filter Events',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Location Filter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Location',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: _locationController,
                    labelText: 'City or Venue',
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Date Range Filter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Date Range',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          controller: _startDateController,
                          labelText: 'From Date',
                          readOnly: true,
                          onTap: () => _selectDate(context, true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextFormField(
                          controller: _endDateController,
                          labelText: 'To Date',
                          readOnly: true,
                          onTap: () => _selectDate(context, false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Price Range Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Price Range',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          controller: _minPriceController,
                          labelText: 'Min Price',
                          prefixText: '\$ ',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextFormField(
                          controller: _maxPriceController,
                          labelText: 'Max Price',
                          prefixText: '\$ ',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Price Options
            Text(
              'Quick Filters',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickFilterChip(
                  label: 'Free Events',
                  onTap: () {
                    _minPriceController.text = '0';
                    _maxPriceController.text = '0';
                  },
                ),
                _QuickFilterChip(
                  label: 'Under \$25',
                  onTap: () {
                    _minPriceController.clear();
                    _maxPriceController.text = '25';
                  },
                ),
                _QuickFilterChip(
                  label: '\$25 - \$50',
                  onTap: () {
                    _minPriceController.text = '25';
                    _maxPriceController.text = '50';
                  },
                ),
                _QuickFilterChip(
                  label: '\$50 - \$100',
                  onTap: () {
                    _minPriceController.text = '50';
                    _maxPriceController.text = '100';
                  },
                ),
                _QuickFilterChip(
                  label: 'This Weekend',
                  onTap: () {
                    final now = DateTime.now();
                    final weekday = now.weekday;
                    final daysUntilSaturday = (6 - weekday) % 7;
                    final saturday = now.add(Duration(days: daysUntilSaturday));
                    final sunday = saturday.add(const Duration(days: 1));

                    setState(() {
                      _startDate = saturday;
                      _endDate = sunday;
                      _startDateController.text = DateFormat('MMM d, yyyy').format(saturday);
                      _endDateController.text = DateFormat('MMM d, yyyy').format(sunday);
                    });
                  },
                ),
                _QuickFilterChip(
                  label: 'Next 7 Days',
                  onTap: () {
                    final now = DateTime.now();
                    final nextWeek = now.add(const Duration(days: 7));

                    setState(() {
                      _startDate = now;
                      _endDate = nextWeek;
                      _startDateController.text = DateFormat('MMM d, yyyy').format(now);
                      _endDateController.text = DateFormat('MMM d, yyyy').format(nextWeek);
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    text: 'APPLY FILTERS',
                    onPressed: _apply,
                    icon: Icons.check,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}