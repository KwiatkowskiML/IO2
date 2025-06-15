import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:resellio/presentation/cart/cubit/cart_cubit.dart';
import 'package:resellio/presentation/cart/cubit/cart_state.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/common_widgets/empty_state_widget.dart';
import 'package:resellio/presentation/common_widgets/primary_button.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/core/utils/responsive_layout.dart';
import 'package:resellio/core/models/cart_model.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/models/models.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CartView();
  }
}

class _CartView extends StatelessWidget {
  const _CartView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return BlocListener<CartCubit, CartState>(
      listener: (context, state) {
        if (state is CartError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Error: ${state.message}')),
                ],
              ),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ));
        }
      },
      child: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          return PageLayout(
            title: 'Shopping Cart',
            showBackButton: true,
            showCartButton: false,
            body: BlocStateWrapper<CartLoaded>(
              state: state,
              onRetry: () => context.read<CartCubit>().fetchCart(),
              builder: (loadedState) {
                if (loadedState.items.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.remove_shopping_cart_outlined,
                    message: 'Your cart is empty',
                    details: 'Find an event and add some tickets to get started!',
                  );
                }

                final isLoading = state is CartLoading;

                return Column(
                  children: [
                    _CartHeader(
                      itemCount: loadedState.items.length,
                      totalPrice: loadedState.totalPrice,
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: loadedState.items.length,
                        itemBuilder: (context, index) {
                          final item = loadedState.items[index];
                          return _CartItemCard(
                            item: item,
                            isLoading: isLoading,
                            onRemove: () => context
                                .read<CartCubit>()
                                .removeItem(item.cartItemId),
                          );
                        },
                      ),
                    ),
                    _CheckoutSection(
                      loadedState: loadedState,
                      isLoading: isLoading,
                      onCheckout: () async {
                        final success = await context
                            .read<CartCubit>()
                            .checkout();
                        if (success && context.mounted) {
                          _showSuccessDialog(context);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
        ),
        title: const Text('Purchase Successful!'),
        content: const Text(
          'Your tickets have been purchased successfully. You can view them in the "My Tickets" section.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home/customer');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  final int itemCount;
  final double totalPrice;

  const _CartHeader({
    required this.itemCount,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final numberFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.shopping_cart,
              color: colorScheme.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$itemCount ${itemCount == 1 ? 'Item' : 'Items'} in Cart',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: ${numberFormat.format(totalPrice)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatefulWidget {
  final CartItem item;
  final bool isLoading;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.isLoading,
    required this.onRemove,
  });

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  Event? _eventDetails;
  bool _loadingEvent = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.ticketType?.eventId != null) {
      _loadEventDetails();
    }
  }

  Future<void> _loadEventDetails() async {
    setState(() => _loadingEvent = true);
    try {
      final eventRepository = context.read<EventRepository>();
      final events = await eventRepository.getEvents();
      final event = events.firstWhere(
            (e) => e.id == widget.item.ticketType!.eventId,
        orElse: () => Event(
          id: widget.item.ticketType!.eventId,
          organizerId: 0,
          name: 'Event #${widget.item.ticketType!.eventId}',
          start: DateTime.now(),
          end: DateTime.now(),
          location: 'Unknown Location',
          status: 'unknown',
          category: [],
          totalTickets: 0,
        ),
      );
      setState(() {
        _eventDetails = event;
        _loadingEvent = false;
      });
    } catch (e) {
      setState(() => _loadingEvent = false);
    }
  }

  void _showEventDetails() {
    if (_eventDetails == null) return;

    showDialog(
      context: context,
      builder: (context) => _EventDetailsDialog(event: _eventDetails!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final numberFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final itemTotal = widget.item.quantity * widget.item.price;

    final isResaleTicket = widget.item.ticketType == null;
    final ticketName = widget.item.ticketType?.description ?? 'Resale Ticket';
    final eventName = _eventDetails?.name ?? 'Loading...';
    final eventDate = _eventDetails?.start;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ticket Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isResaleTicket
                          ? Colors.orange.withOpacity(0.1)
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: isResaleTicket
                          ? Border.all(color: Colors.orange.withOpacity(0.3))
                          : null,
                    ),
                    child: Icon(
                      isResaleTicket
                          ? Icons.sell
                          : Icons.confirmation_number,
                      color: isResaleTicket
                          ? Colors.orange.shade700
                          : colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Ticket Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ticket Type and Status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ticketName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isResaleTicket)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'RESALE',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Event Information
                        if (!isResaleTicket) ...[
                          _InfoRow(
                            icon: Icons.event,
                            label: 'Event',
                            value: _loadingEvent ? 'Loading...' : eventName,
                            isLoading: _loadingEvent,
                          ),
                          const SizedBox(height: 4),
                          if (eventDate != null)
                            _InfoRow(
                              icon: Icons.calendar_today,
                              label: 'Date',
                              value: DateFormat('MMM d, yyyy • h:mm a').format(eventDate),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Pricing Section
              _PricingSection(
                price: widget.item.price,
                quantity: widget.item.quantity,
                itemTotal: itemTotal,
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.isLoading ? null : widget.onRemove,
                      icon: widget.isLoading
                          ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.error,
                        ),
                      )
                          : Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: colorScheme.error,
                      ),
                      label: Text(
                        'Remove',
                        style: TextStyle(color: colorScheme.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _eventDetails != null ? _showEventDetails : null,
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Event Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondaryContainer,
                        foregroundColor: colorScheme.onSecondaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLoading;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: isLoading
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          )
              : Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _PricingSection extends StatelessWidget {
  final double price;
  final int quantity;
  final double itemTotal;

  const _PricingSection({
    required this.price,
    required this.quantity,
    required this.itemTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final numberFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          // Individual Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price per ticket',
                style: theme.textTheme.bodyLarge,
              ),
              Text(
                numberFormat.format(price),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Quantity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantity',
                style: theme.textTheme.bodyLarge,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$quantity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Divider
          Divider(color: colorScheme.outlineVariant),

          const SizedBox(height: 8),

          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                numberFormat.format(itemTotal),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  final CartLoaded loadedState;
  final bool isLoading;
  final VoidCallback onCheckout;

  const _CheckoutSection({
    required this.loadedState,
    required this.isLoading,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final numberFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    // Calculate totals
    final subtotal = loadedState.totalPrice;
    final tax = subtotal * 0.08; // 8% tax
    final processingFee = subtotal * 0.025; // 2.5% processing fee
    final total = subtotal + tax + processingFee;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order Summary Header
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pricing Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  _PricingRow(
                    label: 'Subtotal',
                    value: numberFormat.format(subtotal),
                    isSubtotal: true,
                  ),
                  const SizedBox(height: 8),
                  _PricingRow(
                    label: 'Tax (8%)',
                    value: numberFormat.format(tax),
                  ),
                  const SizedBox(height: 8),
                  _PricingRow(
                    label: 'Processing Fee (2.5%)',
                    value: numberFormat.format(processingFee),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  _PricingRow(
                    label: 'Total',
                    value: numberFormat.format(total),
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Security Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Secure checkout with 256-bit SSL encryption',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Checkout Button
            PrimaryButton(
              text: 'PROCEED TO CHECKOUT',
              isLoading: isLoading,
              onPressed: onCheckout,
              icon: Icons.payment,
              height: 56,
            ),

            const SizedBox(height: 12),

            // Additional Info
            Text(
              'By proceeding, you agree to our Terms of Service and Privacy Policy. Your tickets will be available immediately after purchase.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSubtotal;
  final bool isTotal;

  const _PricingRow({
    required this.label,
    required this.value,
    this.isSubtotal = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )
              : theme.textTheme.bodyLarge,
        ),
        Text(
          value,
          style: isTotal
              ? theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          )
              : isSubtotal
              ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          )
              : theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EventDetailsDialog extends StatelessWidget {
  final Event event;

  const _EventDetailsDialog({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final DateFormat dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.event,
              color: colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.name, style: theme.textTheme.titleLarge),
                Text(
                  'Event Details',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailSection(
                title: 'Event Information',
                items: [
                  _DetailItem(label: 'Event Name', value: event.name),
                  _DetailItem(label: 'Description', value: event.description ?? 'No description'),
                  _DetailItem(label: 'Status', value: event.status.toUpperCase()),
                ],
              ),
              const SizedBox(height: 16),
              _DetailSection(
                title: 'Date & Time',
                items: [
                  _DetailItem(label: 'Date', value: dateFormat.format(event.start)),
                  _DetailItem(
                    label: 'Time',
                    value: '${timeFormat.format(event.start)} - ${timeFormat.format(event.end)}',
                  ),
                  _DetailItem(label: 'Location', value: event.location),
                ],
              ),
              const SizedBox(height: 16),
              _DetailSection(
                title: 'Additional Details',
                items: [
                  _DetailItem(label: 'Total Tickets', value: event.totalTickets.toString()),
                  if (event.minimumAge != null)
                    _DetailItem(label: 'Minimum Age', value: '${event.minimumAge} years'),
                  if (event.category.isNotEmpty)
                    _DetailItem(label: 'Categories', value: event.category.join(', ')),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<_DetailItem> items;

  const _DetailSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  '${item.label}:',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: Text(
                  item.value,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _DetailItem {
  final String label;
  final String value;

  _DetailItem({
    required this.label,
    required this.value,
  });
}