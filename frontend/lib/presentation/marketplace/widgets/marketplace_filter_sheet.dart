import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resellio/presentation/common_widgets/custom_text_form_field.dart';
import 'package:resellio/presentation/common_widgets/primary_button.dart';

class MarketplaceFilterSheet extends StatefulWidget {
  final double? minPrice;
  final double? maxPrice;
  final double? minOriginalPrice;
  final double? maxOriginalPrice;
  final String? venue;
  final String? eventDateFrom;
  final String? eventDateTo;
  final bool? hasSeat;
  final Function(Map<String, dynamic>) onApplyFilters;

  const MarketplaceFilterSheet({
    super.key,
    this.minPrice,
    this.maxPrice,
    this.minOriginalPrice,
    this.maxOriginalPrice,
    this.venue,
    this.eventDateFrom,
    this.eventDateTo,
    this.hasSeat,
    required this.onApplyFilters,
  });

  @override
  State<MarketplaceFilterSheet> createState() => _MarketplaceFilterSheetState();
}

class _MarketplaceFilterSheetState extends State<MarketplaceFilterSheet> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _minOriginalPriceController;
  late TextEditingController _maxOriginalPriceController;
  late TextEditingController _venueController;
  late TextEditingController _eventDateFromController;
  late TextEditingController _eventDateToController;

  DateTime? _eventDateFrom;
  DateTime? _eventDateTo;
  bool? _hasSeat;

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController(
      text: widget.minPrice?.toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.maxPrice?.toString() ?? '',
    );
    _minOriginalPriceController = TextEditingController(
      text: widget.minOriginalPrice?.toString() ?? '',
    );
    _maxOriginalPriceController = TextEditingController(
      text: widget.maxOriginalPrice?.toString() ?? '',
    );
    _venueController = TextEditingController(
      text: widget.venue ?? '',
    );
    _eventDateFromController = TextEditingController();
    _eventDateToController = TextEditingController();

    _hasSeat = widget.hasSeat;

    // Parse date strings if provided
    if (widget.eventDateFrom != null) {
      try {
        _eventDateFrom = DateTime.parse(widget.eventDateFrom!);
        _eventDateFromController.text = DateFormat('MMM d, yyyy').format(_eventDateFrom!);
      } catch (e) {
        // Invalid date format, ignore
      }
    }

    if (widget.eventDateTo != null) {
      try {
        _eventDateTo = DateTime.parse(widget.eventDateTo!);
        _eventDateToController.text = DateFormat('MMM d, yyyy').format(_eventDateTo!);
      } catch (e) {
        // Invalid date format, ignore
      }
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minOriginalPriceController.dispose();
    _maxOriginalPriceController.dispose();
    _venueController.dispose();
    _eventDateFromController.dispose();
    _eventDateToController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2026),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _eventDateFrom = picked;
          _eventDateFromController.text = DateFormat('MMM d, yyyy').format(picked);
        } else {
          _eventDateTo = picked;
          _eventDateToController.text = DateFormat('MMM d, yyyy').format(picked);
        }
      });
    }
  }

  void _applyFilters() {
    final filters = <String, dynamic>{
      'min_price': double.tryParse(_minPriceController.text),
      'max_price': double.tryParse(_maxPriceController.text),
      'min_original_price': double.tryParse(_minOriginalPriceController.text),
      'max_original_price': double.tryParse(_maxOriginalPriceController.text),
      'venue': _venueController.text.isEmpty ? null : _venueController.text,
      'event_date_from': _eventDateFrom?.toIso8601String().split('T')[0],
      'event_date_to': _eventDateTo?.toIso8601String().split('T')[0],
      'has_seat': _hasSeat,
    };

    widget.onApplyFilters(filters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    _minPriceController.clear();
    _maxPriceController.clear();
    _minOriginalPriceController.clear();
    _maxOriginalPriceController.clear();
    _venueController.clear();
    _eventDateFromController.clear();
    _eventDateToController.clear();

    setState(() {
      _eventDateFrom = null;
      _eventDateTo = null;
      _hasSeat = null;
    });

    widget.onApplyFilters({
      'min_price': null,
      'max_price': null,
      'min_original_price': null,
      'max_original_price': null,
      'venue': null,
      'event_date_from': null,
      'event_date_to': null,
      'has_seat': null,
    });
    Navigator.pop(context);
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
        child: SingleChildScrollView(
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
                        'Filter Tickets',
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

              // Venue Filter
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
                          'Venue',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      controller: _venueController,
                      labelText: 'Venue Name',
                      keyboardType: TextInputType.text,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Event Date Range
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
                          'Event Date Range',
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
                            controller: _eventDateFromController,
                            labelText: 'From Date',
                            readOnly: true,
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextFormField(
                            controller: _eventDateToController,
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

              // Resale Price Range
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
                          Icons.sell,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Resale Price Range',
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
                            labelText: 'Min Resale Price',
                            prefixText: '\$ ',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextFormField(
                            controller: _maxPriceController,
                            labelText: 'Max Resale Price',
                            prefixText: '\$ ',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Original Price Range
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
                          'Original Price Range',
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
                            controller: _minOriginalPriceController,
                            labelText: 'Min Original Price',
                            prefixText: '\$ ',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextFormField(
                            controller: _maxOriginalPriceController,
                            labelText: 'Max Original Price',
                            prefixText: '\$ ',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Seat Type Filter
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
                          Icons.event_seat,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Seat Type',
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
                          child: RadioListTile<bool?>(
                            title: const Text('All Tickets'),
                            value: null,
                            groupValue: _hasSeat,
                            onChanged: (value) {
                              setState(() {
                                _hasSeat = value;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool?>(
                            title: const Text('With Seats'),
                            value: true,
                            groupValue: _hasSeat,
                            onChanged: (value) {
                              setState(() {
                                _hasSeat = value;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    RadioListTile<bool?>(
                      title: const Text('General Admission'),
                      value: false,
                      groupValue: _hasSeat,
                      onChanged: (value) {
                        setState(() {
                          _hasSeat = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
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
                    label: 'Under \$50',
                    onTap: () {
                      _minPriceController.clear();
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
                    label: '\$100 - \$200',
                    onTap: () {
                      _minPriceController.text = '100';
                      _maxPriceController.text = '200';
                    },
                  ),
                  _QuickFilterChip(
                    label: 'Over \$200',
                    onTap: () {
                      _minPriceController.text = '200';
                      _maxPriceController.clear();
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
                        _eventDateFrom = saturday;
                        _eventDateTo = sunday;
                        _eventDateFromController.text = DateFormat('MMM d, yyyy').format(saturday);
                        _eventDateToController.text = DateFormat('MMM d, yyyy').format(sunday);
                      });
                    },
                  ),
                  _QuickFilterChip(
                    label: 'Next 7 Days',
                    onTap: () {
                      final now = DateTime.now();
                      final nextWeek = now.add(const Duration(days: 7));

                      setState(() {
                        _eventDateFrom = now;
                        _eventDateTo = nextWeek;
                        _eventDateFromController.text = DateFormat('MMM d, yyyy').format(now);
                        _eventDateToController.text = DateFormat('MMM d, yyyy').format(nextWeek);
                      });
                    },
                  ),
                  _QuickFilterChip(
                    label: 'Great Deals',
                    onTap: () {
                      // Show tickets where resale price is lower than original price
                      // This is a conceptual filter - would need backend support
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Great Deals filter coming soon!'),
                        ),
                      );
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
                      onPressed: _clearFilters,
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
                      onPressed: _applyFilters,
                      icon: Icons.check,
                    ),
                  ),
                ],
              ),
            ],
          ),
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