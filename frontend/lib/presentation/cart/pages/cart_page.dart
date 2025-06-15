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
    final colorScheme = theme.colorScheme;
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
                final isMobile = ResponsiveLayout.isMobile(context);

                return Column(
                  children: [
                    // Cart Header with item count and total
                    Container(
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
                                  '${loadedState.items.length} ${loadedState.items.length == 1 ? 'Item' : 'Items'} in Cart',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total: ${numberFormat.format(loadedState.totalPrice)}',
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
                    ),

                    // Cart Items List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: loadedState.items.length,
                        itemBuilder: (context, index) {
                          final item = loadedState.items[index];
                          final itemTotal = item.quantity * item.price;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: _EnhancedCartItemCard(
                              item: item,
                              itemTotal: itemTotal,
                              isLoading: isLoading,
                              onRemove: () => context
                                  .read<CartCubit>()
                                  .removeItem(item.cartItemId),
                              onQuantityChanged: (newQuantity) {
                                // TODO: Implement quantity update if supported by backend
                              },
                              isMobile: isMobile,
                            ),
                          );
                        },
                      ),
                    ),

                    // Enhanced Checkout Section
                    _EnhancedCheckoutSection(
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

class _EnhancedCartItemCard extends StatelessWidget {
  final dynamic item; // CartItem
  final double itemTotal;
  final bool isLoading;
  final VoidCallback onRemove;
  final Function(int) onQuantityChanged;
  final bool isMobile;

  const _EnhancedCartItemCard({
    required this.item,
    required this.itemTotal,
    required this.isLoading,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final numberFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    // Determine if this is a resale ticket or regular ticket
    final isResaleTicket = item.ticketType == null;
    final ticketName = item.ticketType?.description ?? 'Resale Ticket';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                        // Ticket Type
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

                        // Event Information (if available)
                        if (item.ticketType?.eventId != null) ...[
                          _InfoRow(
                            icon: Icons.event,
                            label: 'Event ID',
                            value: item.ticketType.eventId.toString(),
                          ),
                          const SizedBox(height: 4),
                        ],

                        // Currency
                        _InfoRow(
                          icon: Icons.attach_money,
                          label: 'Currency',
                          value: item.ticketType?.currency ?? 'USD',
                        ),

                        const SizedBox(height: 8),

                        // Availability
                        if (item.ticketType?.maxCount != null)
                          _InfoRow(
                            icon: Icons.inventory_2,
                            label: 'Available',
                            value: '${item.ticketType.maxCount} max per event',
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Pricing Section
              Container(
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
                          numberFormat.format(item.price),
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
                                '${item.quantity}',
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
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : onRemove,
                      icon: isLoading
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
                      onPressed: () {
                        // TODO: Navigate to event details if available
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
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

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
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
          child: Text(
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

class _EnhancedCheckoutSection extends StatelessWidget {
  final dynamic loadedState; // CartLoaded
  final bool isLoading;
  final VoidCallback onCheckout;

  const _EnhancedCheckoutSection({
    required this.loadedState,
    required this.isLoading,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final numberFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final isMobile = ResponsiveLayout.isMobile(context);

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