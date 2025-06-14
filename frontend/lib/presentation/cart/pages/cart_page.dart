import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/services/cart_service.dart';
import 'package:resellio/presentation/common_widgets/primary_button.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    final cartService = context.watch<CartService>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final numberFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return PageLayout(
      title: 'Shopping Cart',
      showBackButton: true,
      body:
          cartService.items.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your cart is empty',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find an event to start adding tickets!',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 16),
                      itemCount: cartService.items.length,
                      itemBuilder: (context, index) {
                        final item = cartService.items[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              item.ticketType.description ?? 'Standard Ticket',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${item.quantity} x ${numberFormat.format(item.ticketType.price)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  numberFormat.format(
                                    item.quantity * item.ticketType.price,
                                  ),
                                  style: theme.textTheme.titleMedium,
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: colorScheme.error,
                                  ),
                                  onPressed: () async {
                                    try {
                                      await cartService.removeItem(item.ticketType);
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error removing item: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // --- Checkout Summary ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal', style: theme.textTheme.bodyLarge),
                            Text(
                              numberFormat.format(cartService.totalPrice),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Fees', style: theme.textTheme.bodyLarge),
                            Text(
                              numberFormat.format(0),
                              style: theme.textTheme.bodyLarge,
                            ), // Placeholder
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: theme.textTheme.titleLarge),
                            Text(
                              numberFormat.format(cartService.totalPrice),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: 'PROCEED TO CHECKOUT',
                          onPressed: () async {
                            try {
                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const AlertDialog(
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text('Processing your order...'),
                                    ],
                                  ),
                                ),
                              );

                              // Call checkout API
                              final success = await cartService.checkout();
                              
                              // Close loading dialog
                              if (mounted) Navigator.of(context).pop();

                              if (success) {
                                // Show success message
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Order successful! Your tickets have been added to "My Tickets".',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                  
                                  // Navigate back or to my tickets page
                                  Navigator.of(context).pop(); // Go back to previous page
                                }
                              } else {
                                // Show error message
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Checkout failed. Please try again.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              // Close loading dialog if still open
                              if (mounted) Navigator.of(context).pop();
                              
                              // Show error message
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
