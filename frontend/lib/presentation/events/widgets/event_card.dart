import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/event_model.dart';
import 'package:go_router/go_router.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  final bool showPrice;
  final double? price;
  final String? priceLabel;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.showPrice = false,
    this.price,
    this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('MMM d');
    final DateFormat timeFormat = DateFormat('HH:mm');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap!();
            } else {
              context.push('/event/${event.id}', extra: event);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced image section with overlay gradient
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                          ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          event.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => _buildImageFallback(colorScheme),
                        ),
                      )
                          : _buildImageFallback(colorScheme),
                    ),

                    // Gradient overlay for better text readability
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),

                    // Status chip with enhanced styling
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(event.status),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          event.status.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Enhanced date badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          dateFormat.format(event.start),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Price badge if applicable
                    if (showPrice && price != null)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '\$${price!.toStringAsFixed(2)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Enhanced content section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event name with better typography
                      Text(
                        event.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Enhanced info row with better spacing
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeFormat.format(event.start),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Enhanced category chips
                      if (event.category.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: event.category
                              .take(2)
                              .map(
                                (category) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.secondary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                category,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Icon(
        Icons.event,
        size: 48,
        color: colorScheme.primary.withOpacity(0.7),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'active' || statusLower == 'created') return Colors.green;
    if (statusLower == 'cancelled') return Colors.red;
    if (statusLower == 'sold out') return Colors.amber.shade800;
    if (statusLower == 'upcoming' || statusLower == 'pending') return Colors.blue;
    return Colors.grey;
  }
}