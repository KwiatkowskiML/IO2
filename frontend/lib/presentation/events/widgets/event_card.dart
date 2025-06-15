import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:resellio/core/models/event_model.dart'; 
import 'package:go_router/go_router.dart'; 

class EventCard extends StatelessWidget {
  final Event event; 
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Formatters for date and time
    final DateFormat dateFormat = DateFormat('MMM d');
    final DateFormat timeFormat = DateFormat('HH:mm');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!(); // Call original onTap if provided
          } else {
            context.push('/event/${event.id}', extra: event);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Stack(
              children: [
                
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.grey.shade800,
                    width: double.infinity,
                    child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                        ? Image.network(
                            event.imageUrl!,
                            fit: BoxFit.cover,
                            
                            loadingBuilder: (
                              context,
                              child,
                              loadingProgress,
                            ) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.broken_image,
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                          )
                        : Icon(
                            Icons.event,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                  ),
                ),

                
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
                    ),
                    child: Text(
                      event.status.toUpperCase(),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ),

                
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dateFormat.format(event.start),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Text(
                    event.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  
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
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  
                  if (event.category.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: event.category
                          .take(
                            2,
                          ) 
                          .map(
                            (category) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer
                                    .withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                category,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
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
