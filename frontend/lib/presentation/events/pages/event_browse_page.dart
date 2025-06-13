import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/models/event_model.dart';
import 'package:resellio/core/models/event_filter_model.dart';
import 'package:resellio/core/services/api_service.dart';
import 'package:resellio/core/utils/responsive_layout.dart';
import 'package:resellio/presentation/events/widgets/event_card.dart';
import 'package:resellio/presentation/events/widgets/event_filter_sheet.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class EventBrowsePage extends StatefulWidget {
  const EventBrowsePage({super.key});

  @override
  State<EventBrowsePage> createState() => _EventBrowsePageState();
}

class _EventBrowsePageState extends State<EventBrowsePage> {
  late Future<List<Event>> _eventsFuture;
  EventFilterModel _currentFilters = const EventFilterModel();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Common categories for quick filters
  final List<String> _categories = [
    'All',
    'Music',
    'Sports',
    'Arts',
    'Food',
    'Technology',
  ];

  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    final apiService = context.read<ApiService>();
    setState(() {
      _eventsFuture = apiService.getEvents();
    });
  }

  void _applyFilters(EventFilterModel newFilters) {
    if (_currentFilters != newFilters) {
      setState(() {
        _currentFilters = newFilters;
        _selectedCategory =
            'All'; // Reset category selection when applying filters
      });
      _loadEvents();
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return EventFilterSheet(
          initialFilters: _currentFilters,
          onApplyFilters: _applyFilters,
        );
      },
    );
  }

  void _performSearch(String query) {
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });
      _loadEvents();
    }
  }

  void _selectCategory(String category) {
    if (category != _selectedCategory) {
      setState(() {
        _selectedCategory = category;
      });
      _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool filtersActive = _currentFilters.hasActiveFilters;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PageLayout(
      title: 'Discover Events',
      actions: [
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: filtersActive ? colorScheme.secondary : null,
          ),
          tooltip: 'Filter Events',
          onPressed: _showFilterSheet,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: _performSearch,
                textInputAction: TextInputAction.search,
              ),
            ),
          ),

          // Category Filters
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => _selectCategory(category),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                );
              },
            ),
          ),

          // Active Filters Indicator
          if (filtersActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    size: 16,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Filters active',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentFilters = const EventFilterModel();
                        _selectedCategory = 'All';
                      });
                      _loadEvents();
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),

          // Results
          Expanded(
            child: FutureBuilder<List<Event>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  print('Error loading events: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load events',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please try again later',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadEvents,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events found',
                          style: theme.textTheme.titleMedium,
                        ),
                        if (_searchQuery.isNotEmpty ||
                            filtersActive ||
                            _selectedCategory != 'All')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Try adjusting your filters or search criteria',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                final events = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent:
                          ResponsiveLayout.isMobile(context) ? 300 : 350,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return EventCard(event: event);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
