import 'package:flutter/material.dart';
import 'package:resellio/core/models/event_filter_model.dart';
import 'package:resellio/presentation/common_widgets/custom_text_form_field.dart';
import 'package:resellio/presentation/common_widgets/primary_button.dart';

class EventFilterSheet extends StatefulWidget {
  final EventFilterModel initialFilters;
  final Function(EventFilterModel) onApplyFilters;

  const EventFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onApplyFilters,
  });

  @override
  State<EventFilterSheet> createState() => _EventFilterSheetState();
}

class _EventFilterSheetState extends State<EventFilterSheet> {
  late EventFilterModel _currentFilters;
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
    _minPriceController.text = _currentFilters.minPrice?.toString() ?? '';
    _maxPriceController.text = _currentFilters.maxPrice?.toString() ?? '';
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _apply() {
    final newFilters = _currentFilters.copyWith(
      minPrice: double.tryParse(_minPriceController.text),
      maxPrice: double.tryParse(_maxPriceController.text),
    );
    widget.onApplyFilters(newFilters);
    Navigator.pop(context);
  }

  void _clear() {
    setState(() {
      _currentFilters = const EventFilterModel();
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Wrap(
        runSpacing: 24,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Events', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          // Price Range
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Price Range', style: theme.textTheme.titleMedium),
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

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clear,
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(text: 'Apply Filters', onPressed: _apply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
