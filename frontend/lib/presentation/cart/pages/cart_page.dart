import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/services/cart_service.dart';
import 'package:resellio/presentation/cart/cubit/cart_cubit.dart';
import 'package:resellio/presentation/cart/cubit/cart_state.dart';
import 'package:resellio/presentation/common_widgets/primary_button.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CartCubit(context.read<CartService>()),
      child: const _CartView(),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView();

  @override
  Widget build(BuildContext context) {
    final cartService = context.watch<CartService>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final numberFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return BlocListener<CartCubit, CartState>(
      listener: (context, state) {
        if (state is CartCheckoutSuccess) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text(
                  'Order successful! Your tickets are in "My Tickets".'),
              backgroundColor: Colors.green,
            ));
          context.go('/home/customer');
        }
        if (state is CartCheckoutFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text('Error: ${state.error}'),
              backgroundColor: Colors.red,
            ));
        }
      },
      child: PageLayout(
        title: 'Shopping Cart',
        showBackButton: true,
        showCartButton: false,
        body: cartService.items.isEmpty
            ? const Center(child: Text('Your cart is empty'))
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
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(item.ticketType?.description ??
                                'Resale Ticket'),
                            subtitle: Text(
                                '${item.quantity} x ${numberFormat.format(item.price)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () =>
                                  cartService.removeItem(item.cartItemId),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total'),
                            Text(numberFormat.format(cartService.totalPrice),
                                style: theme.textTheme.titleLarge),
                          ],
                        ),
                        const SizedBox(height: 24),
                        BlocBuilder<CartCubit, CartState>(
                          builder: (context, state) {
                            return PrimaryButton(
                              text: 'PROCEED TO CHECKOUT',
                              isLoading: state is CartCheckoutInProgress,
                              onPressed: () =>
                                  context.read<CartCubit>().checkout(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
