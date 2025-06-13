import 'package:flutter/material.dart';
import 'package:resellio/core/utils/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:resellio/core/services/cart_service.dart';

class PageLayout extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final double maxContentWidth;
  final bool showBackButton;
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
    this.backgroundColor,
    this.appBarColor,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final bool useAppBar = ResponsiveLayout.isMobile(context);
    final cartItemCount = context.watch<CartService>().itemCount;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cartIconButton = Badge(
      label: Text(
        cartItemCount.toString(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      isLabelVisible: cartItemCount > 0,
      backgroundColor: colorScheme.primary,
      largeSize: 20,
      child: IconButton(
        tooltip: 'Shopping Cart',
        icon: const Icon(Icons.shopping_cart_outlined),
        onPressed: () {
          context.push('/cart');
        },
      ),
    );

    return Scaffold(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      appBar:
          useAppBar
              ? AppBar(
                backgroundColor: appBarColor ?? colorScheme.surface,
                scrolledUnderElevation: 2,
                elevation: 0,
                centerTitle: false,
                title: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading:
                    showBackButton
                        ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            }
                          },
                        )
                        : null,
                actions: [
                  if (actions != null) ...actions!,
                  cartIconButton,
                  const SizedBox(width: 8),
                ],
              )
              : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!useAppBar)
            Container(
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
                        }
                      },
                    ),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (actions != null) ...actions!,
                      if (actions != null && actions!.isNotEmpty)
                        const SizedBox(width: 16),
                      cartIconButton,
                    ],
                  ),
                ],
              ),
            ),

          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: useAppBar ? 0 : 24.0,
                  ),
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
}
