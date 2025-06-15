import 'package:flutter/material.dart';
import 'package:resellio/core/utils/responsive_layout.dart';

class ContentGrid<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final String emptyMessage;
  final String emptyDetails;
  final IconData emptyIcon;
  final double maxCrossAxisExtent;
  final double childAspectRatio;
  final Widget? header;
  final EdgeInsets padding;
  final double spacing;

  const ContentGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.emptyMessage = 'No items found',
    this.emptyDetails = 'Try adjusting your search or filters',
    this.emptyIcon = Icons.search_off,
    this.maxCrossAxisExtent = 350,
    this.childAspectRatio = 0.75,
    this.header,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    return CustomScrollView(
      slivers: [
        if (header != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: padding,
              child: header!,
            ),
          ),
        SliverPadding(
          padding: padding,
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: ResponsiveLayout.isMobile(context)
                  ? maxCrossAxisExtent * 0.85
                  : maxCrossAxisExtent,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) => AnimatedContainer(
                duration: Duration(milliseconds: 200 + (index * 50)),
                curve: Curves.easeOutQuart,
                child: itemBuilder(context, items[index], index),
              ),
              childCount: items.length,
            ),
          ),
        ),
        // Add some bottom padding for better scrolling experience
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      emptyIcon,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              emptyMessage,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              emptyDetails,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}