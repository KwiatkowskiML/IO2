import 'package:flutter/material.dart';
import 'package:resellio/core/models/event_filter_model.dart';
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
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
    _nameController.text = _currentFilters.name ?? '';
    _locationController.text = _currentFilters.location ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _apply() {
    final newFilters = _currentFilters.copyWith(
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      location: _locationController.text.isNotEmpty ? _locationController.text : null,
    );
    widget.onApplyFilters(newFilters);
    Navigator.pop(context);
  }

  void _clear() {
    setState(() {
      _currentFilters = const EventFilterModel();
      _nameController.clear();
      _locationController.clear();
    });
  }

  Future<void> _selectDateFrom() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentFilters.startDateFrom ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select start date from',
    );
    if (picked != null) {
      setState(() {
        _currentFilters = _currentFilters.copyWith(startDateFrom: picked);
      });
    }
  }

  Future<void> _selectDateTo() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentFilters.startDateTo ?? 
          (_currentFilters.startDateFrom?.add(const Duration(days: 7)) ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: _currentFilters.startDateFrom ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select start date to',
    );
    if (picked != null) {
      setState(() {
        _currentFilters = _currentFilters.copyWith(startDateTo: picked);
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day}/${date.month}/${date.year}';
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
        runSpacing: 20,
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

          // Event Name Filter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Event Name', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Search by event name',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),

          // Location Filter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Enter location name',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),

          // Date Range Filter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date Range', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDateFrom,
                      icon: const Icon(Icons.calendar_today),
                      label: Text('From: ${_formatDate(_currentFilters.startDateFrom)}'),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDateTo,
                      icon: const Icon(Icons.calendar_today),
                      label: Text('To: ${_formatDate(_currentFilters.startDateTo)}'),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
              if (_currentFilters.startDateFrom != null || _currentFilters.startDateTo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentFilters = _currentFilters.copyWith(
                              startDateFrom: null,
                              startDateTo: null,
                            );
                          });
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear dates'),
                      ),
                    ],
                  ),
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
