import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/marketplace/cubit/marketplace_cubit.dart';
import 'package:resellio/presentation/marketplace/cubit/marketplace_state.dart';
import 'package:resellio/presentation/common_widgets/enhanced_search_bar.dart';
import 'package:resellio/presentation/common_widgets/category_chips.dart';
import 'package:resellio/presentation/common_widgets/content_grid.dart';
import 'package:resellio/presentation/marketplace/widgets/marketplace_filter_sheet.dart';
import 'package:resellio/presentation/marketplace/widgets/resale_ticket_card.dart';

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
      MarketplaceCubit(context.read<ResaleRepository>())..loadListings(),
      child: const _MarketplaceView(),
    );
  }
}

class _MarketplaceView extends StatefulWidget {
  const _MarketplaceView();

  @override
  State<_MarketplaceView> createState() => _MarketplaceViewState();
}

class _MarketplaceViewState extends State<_MarketplaceView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  double? _minOriginalPrice;
  double? _maxOriginalPrice;
  String? _venue;
  String? _eventDateFrom;
  String? _eventDateTo;
  bool? _hasSeat;
  int? _eventId;

  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  final List<String> _priceRanges = [
    'All Prices',
    'Under \$50',
    '\$50 - \$100',
    '\$100 - \$200',
    'Over \$200',
  ];

  final List<String> _sortOptions = [
    'Event Date',
    'Price: Low to High',
    'Price: High to Low',
    'Event Name',
  ];

  String _selectedPriceRange = 'All Prices';
  String _selectedSort = 'Event Date';
  String _sortBy = 'event_date';
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
      _loadMoreListings();
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
        return MarketplaceFilterSheet(
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          minOriginalPrice: _minOriginalPrice,
          maxOriginalPrice: _maxOriginalPrice,
          venue: _venue,
          eventDateFrom: _eventDateFrom,
          eventDateTo: _eventDateTo,
          hasSeat: _hasSeat,
          onApplyFilters: (filters) {
            setState(() {
              _minPrice = filters['min_price'];
              _maxPrice = filters['max_price'];
              _minOriginalPrice = filters['min_original_price'];
              _maxOriginalPrice = filters['max_original_price'];
              _venue = filters['venue'];
              _eventDateFrom = filters['event_date_from'];
              _eventDateTo = filters['event_date_to'];
              _hasSeat = filters['has_seat'];
              _currentPage = 1;
              _hasMoreData = true;
            });
            _loadListingsWithFilters(reset: true);
          },
        );
      },
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Tickets'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sortOptions.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: _selectedSort,
              onChanged: (value) {
                setState(() {
                  _selectedSort = value!;
                  switch (value) {
                    case 'Event Date':
                      _sortBy = 'event_date';
                      _sortOrder = 'asc';
                      break;
                    case 'Price: Low to High':
                      _sortBy = 'resell_price';
                      _sortOrder = 'asc';
                      break;
                    case 'Price: High to Low':
                      _sortBy = 'resell_price';
                      _sortOrder = 'desc';
                      break;
                    case 'Event Name':
                      _sortBy = 'event_name';
                      _sortOrder = 'asc';
                      break;
                  }
                });
              },
            );
          }).toList(),
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
              _loadListingsWithFilters(reset: true);
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
        _loadListingsWithFilters(reset: true);
      }
    });
  }

  void _onPriceRangeChanged(String range) {
    setState(() {
      _selectedPriceRange = range;
      _currentPage = 1;
      _hasMoreData = true;
    });

    double? min, max;
    switch (range) {
      case 'Under \$50':
        min = null;
        max = 50;
        break;
      case '\$50 - \$100':
        min = 50;
        max = 100;
        break;
      case '\$100 - \$200':
        min = 100;
        max = 200;
        break;
      case 'Over \$200':
        min = 200;
        max = null;
        break;
      default:
        min = null;
        max = null;
    }

    setState(() {
      _minPrice = min;
      _maxPrice = max;
    });

    _loadListingsWithFilters(reset: true);
  }

  void _loadListingsWithFilters({bool reset = false}) {
    if (reset) {
      context.read<MarketplaceCubit>().loadListings(
        page: _currentPage,
        limit: _pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        eventId: _eventId,
        venue: _venue,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minOriginalPrice: _minOriginalPrice,
        maxOriginalPrice: _maxOriginalPrice,
        eventDateFrom: _eventDateFrom,
        eventDateTo: _eventDateTo,
        hasSeat: _hasSeat,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        reset: true,
      );
    } else {
      _loadMoreListings();
    }
  }

  void _loadMoreListings() {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    context.read<MarketplaceCubit>().loadMoreListings(
      page: _currentPage + 1,
      limit: _pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      eventId: _eventId,
      venue: _venue,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minOriginalPrice: _minOriginalPrice,
      maxOriginalPrice: _maxOriginalPrice,
      eventDateFrom: _eventDateFrom,
      eventDateTo: _eventDateTo,
      hasSeat: _hasSeat,
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

  bool get _filtersActive =>
      _minPrice != null ||
          _maxPrice != null ||
          _minOriginalPrice != null ||
          _maxOriginalPrice != null ||
          _venue != null ||
          _eventDateFrom != null ||
          _eventDateTo != null ||
          _hasSeat != null ||
          _searchQuery.isNotEmpty ||
          _selectedPriceRange != 'All Prices';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PageLayout(
      title: 'Marketplace',
      actions: [
        IconButton(
          icon: Icon(
            Icons.sort,
            color: colorScheme.onSurface,
          ),
          tooltip: 'Sort Tickets',
          onPressed: _showSortDialog,
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
                  colorScheme.tertiaryContainer.withOpacity(0.3),
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
                      Row(
                        children: [
                          Icon(
                            Icons.storefront,
                            color: colorScheme.tertiary,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ticket Marketplace',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find great deals on tickets from other fans',
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
                    hintText: 'Search tickets by event, artist, venue...',
                    searchQuery: _searchQuery,
                    onSearchChanged: _onSearchChanged,
                    filtersActive: _filtersActive,
                    onFilterTap: _showFilterSheet,
                  ),
                ),

                // Price Range Chips
                CategoryChips(
                  categories: _priceRanges,
                  selectedCategory: _selectedPriceRange,
                  onCategoryChanged: _onPriceRangeChanged,
                ),

                // Active filters indicator
                if (_filtersActive)
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
                        if (_venue != null)
                          Chip(
                            label: Text('Venue: $_venue'),
                            onDeleted: () {
                              setState(() {
                                _venue = null;
                                _currentPage = 1;
                                _hasMoreData = true;
                              });
                              _loadListingsWithFilters(reset: true);
                            },
                          ),
                        if (_eventDateFrom != null || _eventDateTo != null)
                          Chip(
                            label: Text('Date Filter Active'),
                            onDeleted: () {
                              setState(() {
                                _eventDateFrom = null;
                                _eventDateTo = null;
                                _currentPage = 1;
                                _hasMoreData = true;
                              });
                              _loadListingsWithFilters(reset: true);
                            },
                          ),
                        if (_hasSeat != null)
                          Chip(
                            label: Text(_hasSeat! ? 'With Seats' : 'General Admission'),
                            onDeleted: () {
                              setState(() {
                                _hasSeat = null;
                                _currentPage = 1;
                                _hasMoreData = true;
                              });
                              _loadListingsWithFilters(reset: true);
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Marketplace Content
          Expanded(
            child: BlocConsumer<MarketplaceCubit, MarketplaceState>(
              listener: (context, state) {
                if (state is MarketplaceLoaded &&
                    state is! MarketplacePurchaseInProgress) {
                  // Success message could be shown here if needed
                }
              },
              builder: (context, state) {
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _currentPage = 1;
                      _hasMoreData = true;
                    });
                    _loadListingsWithFilters(reset: true);
                  },
                  child: BlocStateWrapper<MarketplaceLoaded>(
                    state: state,
                    onRetry: () => _loadListingsWithFilters(reset: true),
                    builder: (loadedState) {
                      if (loadedState.listings.isEmpty && !_isLoadingMore) {
                        return _buildEmptyMarketplace(context);
                      }

                      return CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: _buildMarketplaceStats(loadedState),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 350,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                  final listing = loadedState.listings[index];
                                  final isPurchasing = state is MarketplacePurchaseInProgress &&
                                      state.processingTicketId == listing.ticketId;

                                  return ResaleTicketCard(
                                    listing: listing,
                                    isPurchasing: isPurchasing,
                                    onPurchase: () => _purchaseTicket(context, listing),
                                  );
                                },
                                childCount: loadedState.listings.length,
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
                          if (!_hasMoreData && loadedState.listings.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'No more tickets to load',
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
                      );
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

  Widget _buildMarketplaceStats(MarketplaceLoaded state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalListings = state.listings.length;
    final avgPrice = totalListings > 0
        ? state.listings.map((l) => l.resellPrice).reduce((a, b) => a + b) / totalListings
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              icon: Icons.confirmation_number,
              label: 'Available',
              value: totalListings.toString(),
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatChip(
              icon: Icons.trending_down,
              label: 'Avg Price',
              value: NumberFormat.currency(locale: 'en_US', symbol: '\$').format(avgPrice),
              color: colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMarketplace(BuildContext context) {
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
                color: colorScheme.tertiaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store_outlined,
                size: 64,
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Tickets Available',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are currently no tickets listed for resale.\nCheck back later for new listings.',
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
                  _selectedPriceRange = 'All Prices';
                  _minPrice = null;
                  _maxPrice = null;
                  _minOriginalPrice = null;
                  _maxOriginalPrice = null;
                  _venue = null;
                  _eventDateFrom = null;
                  _eventDateTo = null;
                  _hasSeat = null;
                  _eventId = null;
                  _currentPage = 1;
                  _hasMoreData = true;
                });
                _loadListingsWithFilters(reset: true);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseTicket(BuildContext context, ResaleTicketListing listing) async {
    try {
      await context.read<MarketplaceCubit>().purchaseTicket(listing.ticketId);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${listing.eventName} ticket purchased successfully!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Purchase failed: ${e.toString()}')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}