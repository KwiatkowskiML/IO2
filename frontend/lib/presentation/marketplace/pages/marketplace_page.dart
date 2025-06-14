import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/marketplace/cubit/marketplace_cubit.dart';
import 'package:resellio/presentation/marketplace/cubit/marketplace_state.dart';

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

class _MarketplaceView extends StatelessWidget {
  const _MarketplaceView();

  void _showFilters(
      BuildContext context, double? currentMin, double? currentMax) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _FilterBottomSheet(
        minPrice: currentMin,
        maxPrice: currentMax,
        onApplyFilters: (min, max) {
          context
              .read<MarketplaceCubit>()
              .loadListings(minPrice: min, maxPrice: max);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Marketplace',
      actions: [
        BlocBuilder<MarketplaceCubit, MarketplaceState>(
          builder: (context, state) {
            return IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                double? min, max;
                if (state is MarketplaceLoaded) {
                  // Pass current filters if they exist
                }
                _showFilters(context, min, max);
              },
            );
          },
        ),
      ],
      body: BlocListener<MarketplaceCubit, MarketplaceState>(
        listener: (context, state) {
          if (state is MarketplaceLoaded &&
              state is! MarketplacePurchaseInProgress) {
            // Can be used to show "Purchase successful" if needed,
            // but for now, the list just refreshes.
          }
        },
        child: RefreshIndicator(
          onRefresh: () => context.read<MarketplaceCubit>().loadListings(),
          child: BlocBuilder<MarketplaceCubit, MarketplaceState>(
            builder: (context, state) {
              return BlocStateWrapper<MarketplaceLoaded>(
                state: state,
                onRetry: () =>
                    context.read<MarketplaceCubit>().loadListings(),
                builder: (loadedState) {
                  if (loadedState.listings.isEmpty) {
                    return const Center(
                        child: Text('No tickets on the marketplace.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: loadedState.listings.length,
                    itemBuilder: (context, index) {
                      final listing = loadedState.listings[index];
                      final isPurchasing =
                          state is MarketplacePurchaseInProgress &&
                              state.processingTicketId == listing.ticketId;

                      return _TicketListingCard(
                        listing: listing,
                        isPurchasing: isPurchasing,
                        onPurchaseTicket: () async {
                          try {
                            await context
                                .read<MarketplaceCubit>()
                                .purchaseTicket(listing.ticketId);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${listing.eventName} ticket purchased successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                          } catch (e) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Purchase failed: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                          }
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TicketListingCard extends StatelessWidget {
  final ResaleTicketListing listing;
  final VoidCallback onPurchaseTicket;
  final bool isPurchasing;

  const _TicketListingCard({
    required this.listing,
    required this.onPurchaseTicket,
    required this.isPurchasing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final savings = listing.originalPrice - listing.resellPrice;
    final savingsPercent = listing.originalPrice > 0
        ? (savings / listing.originalPrice * 100).round()
        : 0;

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
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (savings > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('$savingsPercent% OFF',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (savings > 0)
                        Text(
                          '\$${listing.originalPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: colorScheme.onSurfaceVariant),
                        ),
                      Text(
                        '\$${listing.resellPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: isPurchasing ? null : onPurchaseTicket,
                  child: isPurchasing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Buy Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final double? minPrice;
  final double? maxPrice;
  final Function(double?, double?) onApplyFilters;

  const _FilterBottomSheet(
      {this.minPrice, this.maxPrice, required this.onApplyFilters});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _minPriceController =
        TextEditingController(text: widget.minPrice?.toString() ?? '');
    _maxPriceController =
        TextEditingController(text: widget.maxPrice?.toString() ?? '');
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
          Text('Filter Tickets',
              style: Theme.of(context).textTheme.headlineSmall),
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
                      border: OutlineInputBorder()),
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
                      border: OutlineInputBorder()),
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
