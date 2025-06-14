import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/cart/cubit/cart_cubit.dart';
import 'package:resellio/presentation/cart/cubit/cart_state.dart';
import 'package:resellio/presentation/common_widgets/bloc_state_wrapper.dart';
import 'package:resellio/presentation/common_widgets/primary_button.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CartCubit(context.read<CartRepository>())..fetchCart(),
      child: const _CartView(),
    );
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
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
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
                  return const Center(child: Text('Your cart is empty'));
                } else {
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 16),
                          itemCount: loadedState.items.length,
                          itemBuilder: (context, index) {
                            final item = loadedState.items[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: ListTile(
                                title: Text(item.ticketType?.description ??
                                    'Resale Ticket'),
                                subtitle: Text(
                                    '${item.quantity} x ${numberFormat.format(item.price)}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () => context
                                      .read<CartCubit>()
                                      .removeItem(item.cartItemId),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total'),
                                Text(
                                    numberFormat
                                        .format(loadedState.totalPrice),
                                    style: theme.textTheme.titleLarge),
                              ],
                            ),
                            const SizedBox(height: 24),
                            PrimaryButton(
                              text: 'PROCEED TO CHECKOUT',
                              isLoading: state is CartLoading,
                              onPressed: () async {
                                final success = await context
                                    .read<CartCubit>()
                                    .checkout();
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Purchase Successful!'),
                                          backgroundColor: Colors.green));
                                  context.go('/home/customer');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
