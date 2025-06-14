import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/services/api_service.dart';
import 'package:resellio/core/services/cart_service.dart';
import 'package:resellio/core/models/ticket_model.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

// Model for resale ticket listings
class ResaleTicketListing {
  final int ticketId;
  final double originalPrice;
  final double resellPrice;
  final String eventName;
  final DateTime eventDate;
  final String venueName;
  final String ticketTypeDescription;
  final String? seat;

  ResaleTicketListing({
    required this.ticketId,
    required this.originalPrice,
    required this.resellPrice,
    required this.eventName,
    required this.eventDate,
    required this.venueName,
    required this.ticketTypeDescription,
    this.seat,
  });

  factory ResaleTicketListing.fromJson(Map<String, dynamic> json) {
    return ResaleTicketListing(
      ticketId: json['ticket_id'],
      originalPrice: (json['original_price'] as num).toDouble(),
      resellPrice: (json['resell_price'] as num).toDouble(),
      eventName: json['event_name'],
      eventDate: DateTime.parse(json['event_date']),
      venueName: json['venue_name'],
      ticketTypeDescription: json['ticket_type_description'],
      seat: json['seat'],
    );
  }
}

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  List<ResaleTicketListing> _listings = [];
  bool _isLoading = true;
  String? _error;
  
  // Filter state
  double? _minPrice;
  double? _maxPrice;
  int? _eventId;

  @override
  void initState() {
    super.initState();
    _loadMarketplaceListings();
  }

  Future<void> _loadMarketplaceListings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final listings = await apiService.getMarketplaceListings(
        eventId: _eventId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
      
      setState(() {
        _listings = listings.map((json) => ResaleTicketListing.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart(ResaleTicketListing listing) async {
    try {
      print('Marketplace: Adding ticket ${listing.ticketId} to cart');
      
      // Use the cart service to add resale ticket
      await context.read<CartService>().addResaleTicket(
        listing.ticketId,
        listing.eventName,
        listing.ticketTypeDescription ?? 'Standard Ticket',
        listing.resellPrice,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${listing.eventName} ticket added to cart!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadMarketplaceListings(); // Refresh listings
      }
    } catch (e) {
      print('Marketplace: Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        onApplyFilters: (min, max) {
          setState(() {
            _minPrice = min;
            _maxPrice = max;
          });
          _loadMarketplaceListings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Marketplace',
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilters,
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadMarketplaceListings,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMarketplaceListings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_listings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No tickets available for resale',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later for new listings!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _listings.length,
      itemBuilder: (context, index) {
        final listing = _listings[index];
        return _TicketListingCard(
          listing: listing,
          onAddToCart: () => _addToCart(listing),
        );
      },
    );
  }
}

class _TicketListingCard extends StatelessWidget {
  final ResaleTicketListing listing;
  final VoidCallback onAddToCart;

  const _TicketListingCard({
    required this.listing,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final savings = listing.originalPrice - listing.resellPrice;
    final savingsPercent = (savings / listing.originalPrice * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.eventName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.venueName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (savings > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$savingsPercent% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(listing.eventDate),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.confirmation_number,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  listing.ticketTypeDescription,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (listing.seat != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.event_seat,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Seat: ${listing.seat}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (savings > 0) ...[
                        Text(
                          '\$${listing.originalPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        '\$${listing.resellPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onAddToCart,
                  child: const Text('Add to Cart'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${_getDayName(date.weekday)} at ${_formatTime(date)}';
    } else {
      return '${date.month}/${date.day}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final double? minPrice;
  final double? maxPrice;
  final Function(double?, double?) onApplyFilters;

  const _FilterBottomSheet({
    this.minPrice,
    this.maxPrice,
    required this.onApplyFilters,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController(
      text: widget.minPrice?.toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.maxPrice?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Tickets',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _minPriceController.clear();
                    _maxPriceController.clear();
                    widget.onApplyFilters(null, null);
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final minPrice = double.tryParse(_minPriceController.text);
                    final maxPrice = double.tryParse(_maxPriceController.text);
                    widget.onApplyFilters(minPrice, maxPrice);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
