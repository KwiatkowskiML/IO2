import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/utils/responsive_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:resellio/presentation/cart/cubit/cart_cubit.dart';
import 'package:resellio/presentation/cart/cubit/cart_state.dart';

class PageLayout extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final double maxContentWidth;
  final bool showBackButton;
  final bool showCartButton;
  final Color? backgroundColor;
  final Color? appBarColor;
  final Widget? bottomNavigationBar;

  const PageLayout({
    super.key,
    required this.title,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.maxContentWidth = 1200,
    this.showBackButton = false,
    this.showCartButton = true,
    this.backgroundColor,
    this.appBarColor,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      appBar: isMobile ? _buildMobileAppBar(context, theme, colorScheme) : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) _buildDesktopHeader(context, theme, colorScheme),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: isMobile ? 0 : 24.0),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  PreferredSizeWidget _buildMobileAppBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: appBarColor ?? colorScheme.surface,
      scrolledUnderElevation: 2,
      elevation: 0,
      centerTitle: false,
      title: Text(
        title,
        style: theme.textTheme.titleLarge,
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home/customer');
                }
              },
            )
          : null,
      actions: [
        if (actions != null) ...actions!,
        if (showCartButton) const _CartIconButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDesktopHeader(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: appBarColor ?? colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home/customer');
                }
              },
            ),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineMedium,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (actions != null) ...actions!,
              if (actions != null && actions!.isNotEmpty)
                const SizedBox(width: 16),
              if (showCartButton) const _CartIconButton(),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartIconButton extends StatelessWidget {
  const _CartIconButton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        int count = 0;
        bool hasError = false;

        if (state is CartLoaded) {
          count = state.items.length;
        } else if (state is CartError) {
          hasError = true;
          count = 0; // Don't show count when there's an error
        } else if (state is CartLoading) {
          // Show previous count if available
          if (state.previousItems.isNotEmpty) {
            count = state.previousItems.length;
          }
        }

        return Badge(
          label: hasError
              ? const Icon(Icons.error, size: 12, color: Colors.white)
              : Text(
            count.toString(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          isLabelVisible: count > 0 || hasError,
          backgroundColor: hasError ? Colors.red : colorScheme.primary,
          largeSize: 20,
          child: IconButton(
            tooltip: hasError ? 'Cart Error - Tap to refresh' : 'Shopping Cart',
            icon: Icon(
              hasError ? Icons.shopping_cart_outlined : Icons.shopping_cart_outlined,
              color: hasError ? Colors.red.withOpacity(0.7) : null,
            ),
            onPressed: () {
              if (hasError) {
                // Try to refresh cart before navigating
                context.read<CartCubit>().clearErrorAndRefresh();
              }
              context.go('/cart');
            },
          ),
        );
      },
    );
  }
}
