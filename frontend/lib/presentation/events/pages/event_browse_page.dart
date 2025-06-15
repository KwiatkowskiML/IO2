import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/event_filter_model.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/utils/responsive_layout.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/events/cubit/event_browse_cubit.dart';
import 'package:resellio/presentation/events/cubit/event_browse_state.dart';
import 'package:resellio/presentation/events/widgets/event_card.dart';
import 'package:resellio/presentation/events/widgets/event_filter_sheet.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/common_widgets/enhanced_search_bar.dart';
import 'package:resellio/presentation/common_widgets/category_chips.dart';
import 'package:resellio/presentation/common_widgets/content_grid.dart';

class EventBrowsePage extends StatelessWidget {
  const EventBrowsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
      EventBrowseCubit(context.read<EventRepository>())..loadEvents(),
      child: const _EventBrowseView(),
    );
  }
}

class _EventBrowseView extends StatefulWidget {
  const _EventBrowseView();

  @override
  State<_EventBrowseView> createState() => _EventBrowseViewState();
}

class _EventBrowseViewState extends State<_EventBrowseView> {
  EventFilterModel _currentFilters = const EventFilterModel();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  final List<String> _categories = [
    'All',
    'Music',
    'Sports',
    'Arts',
    'Food',
    'Technology',
  ];

  String _selectedCategory = 'All';
  String _sortBy = 'start_date';
  String _sortOrder = 'asc';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreEvents();
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
          showAdvancedFilters: false, // Hide organizer, status, minimum age filters
          onApplyFilters: (newFilters) {
            setState(() {
              _currentFilters = newFilters;
              _currentPage = 1;
              _hasMoreData = true;
            });
            _loadEventsWithFilters(reset: true);
          },
        );
      },
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Events'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Sort by'),
              subtitle: DropdownButton<String>(
                value: _sortBy,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'start_date', child: Text('Event Date')),
                  DropdownMenuItem(value: 'name', child: Text('Event Name')),
                  DropdownMenuItem(value: 'creation_date', child: Text('Recently Added')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Order'),
              subtitle: DropdownButton<String>(
                value: _sortOrder,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                  DropdownMenuItem(value: 'desc', child: Text('Descending')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortOrder = value!;
                  });
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentPage = 1;
                _hasMoreData = true;
              });
              _loadEventsWithFilters(reset: true);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
      _hasMoreData = true;
    });

    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        _loadEventsWithFilters(reset: true);
      }
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _currentPage = 1;
      _hasMoreData = true;
    });
    _loadEventsWithFilters(reset: true);
  }

  void _loadEventsWithFilters({bool reset = false}) {
    if (reset) {
      context.read<EventBrowseCubit>().loadEvents(
        page: _currentPage,
        limit: _pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        location: _currentFilters.location,
        startDateFrom: _currentFilters.startDateFrom,
        startDateTo: _currentFilters.startDateTo,
        minPrice: _currentFilters.minPrice,
        maxPrice: _currentFilters.maxPrice,
        categories: _selectedCategory == 'All' ? null : _selectedCategory,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        reset: true,
      );
    } else {
      _loadMoreEvents();
    }
  }

  void _loadMoreEvents() {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    context.read<EventBrowseCubit>().loadMoreEvents(
      page: _currentPage + 1,
      limit: _pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      location: _currentFilters.location,
      startDateFrom: _currentFilters.startDateFrom,
      startDateTo: _currentFilters.startDateTo,
      minPrice: _currentFilters.minPrice,
      maxPrice: _currentFilters.maxPrice,
      categories: _selectedCategory == 'All' ? null : _selectedCategory,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    ).then((hasMore) {
      setState(() {
        _isLoadingMore = false;
        _hasMoreData = hasMore;
        if (hasMore) _currentPage++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool filtersActive = _currentFilters.hasActiveFilters ||
        _selectedCategory != 'All' ||
        _searchQuery.isNotEmpty;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PageLayout(
      title: 'Discover Events',
      actions: [
        IconButton(
          icon: Icon(
            Icons.sort,
            color: colorScheme.onSurface,
          ),
          tooltip: 'Sort Events',
          onPressed: _showSortDialog,
        ),
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
          // Enhanced Header Section
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.surface,
                ],
              ),
            ),
            child: Column(
              children: [
                // Welcome Message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Your Next',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        'Amazing Experience',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover events that match your interests',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Enhanced Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: EnhancedSearchBar(
                    controller: _searchController,
                    hintText: 'Search events, artists, venues...',
                    searchQuery: _searchQuery,
                    onSearchChanged: _onSearchChanged,
                    filtersActive: filtersActive,
                  ),
                ),

                // Category Chips
                CategoryChips(
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: _onCategoryChanged,
                ),

                // Active filters indicator
                if (filtersActive)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          Chip(
                            label: Text('Search: $_searchQuery'),
                            onDeleted: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                        if (_currentFilters.location != null)
                          Chip(
                            label: Text('Location: ${_currentFilters.location}'),
                            onDeleted: () {
                              setState(() {
                                _currentFilters = _currentFilters.copyWith(location: null);
                                _currentPage = 1;
                                _hasMoreData = true;
                              });
                              _loadEventsWithFilters(reset: true);
                            },
                          ),
                        if (_currentFilters.minPrice != null || _currentFilters.maxPrice != null)
                          Chip(
                            label: Text(
                                'Price: \$${_currentFilters.minPrice?.toStringAsFixed(0) ?? '0'} - \$${_currentFilters.maxPrice?.toStringAsFixed(0) ?? '∞'}'
                            ),
                            onDeleted: () {
                              setState(() {
                                _currentFilters = _currentFilters.copyWith(
                                  minPrice: null,
                                  maxPrice: null,
                                );
                                _currentPage = 1;
                                _hasMoreData = true;
                              });
                              _loadEventsWithFilters(reset: true);
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Events Grid
          Expanded(
            child: BlocBuilder<EventBrowseCubit, EventBrowseState>(
              builder: (context, state) {
                return BlocStateWrapper<EventBrowseLoaded>(
                  state: state,
                  onRetry: () => _loadEventsWithFilters(reset: true),
                  builder: (loadedState) {
                    if (loadedState.events.isEmpty && !_isLoadingMore) {
                      return _buildEmptyState(context);
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _currentPage = 1;
                          _hasMoreData = true;
                        });
                        _loadEventsWithFilters(reset: true);
                      },
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: ResponsiveLayout.isMobile(context) ? 350 * 0.85 : 350,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                    (context, index) => AnimatedContainer(
                                  duration: Duration(milliseconds: 200 + (index * 50)),
                                  curve: Curves.easeOutQuart,
                                  child: EventCard(event: loadedState.events[index]),
                                ),
                                childCount: loadedState.events.length,
                              ),
                            ),
                          ),
                          if (_isLoadingMore)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                            ),
                          if (!_hasMoreData && loadedState.events.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'No more events to load',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 80),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Events Found',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any events matching your criteria.\nTry adjusting your search or filters.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                  _currentFilters = const EventFilterModel();
                  _currentPage = 1;
                  _hasMoreData = true;
                });
                _loadEventsWithFilters(reset: true);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}