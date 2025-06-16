import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/models.dart';

class TicketCard extends StatelessWidget {
  final TicketDetailsModel ticket;
  final bool isProcessing;
  final VoidCallback? onResell;
  final VoidCallback? onCancelResale;
  final VoidCallback? onDownload;

  const TicketCard({
    super.key,
    required this.ticket,
    this.isProcessing = false,
    this.onResell,
    this.onCancelResale,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isResale = ticket.resellPrice != null;
    final bool isPast = ticket.eventStartDate != null &&
        ticket.eventStartDate!.isBefore(DateTime.now());
    final bool isUpcoming = ticket.eventStartDate != null &&
        ticket.eventStartDate!.isAfter(DateTime.now());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: isProcessing ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: _getBorderColor(colorScheme, isResale, isPast, isUpcoming),
            width: _getBorderWidth(isResale, isPast, isUpcoming),
          ),
        ),
        child: Column(
          children: [
            // Status header
            if (isResale || isPast)
              _buildStatusHeader(context, isResale, isPast),

            // Processing indicator
            if (isProcessing)
              LinearProgressIndicator(
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header row with date and event info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateBadge(context, isPast, isUpcoming),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildEventInfo(context, isResale),
                      ),
                      _buildTicketTypeChip(context),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Ticket details
                  _buildTicketDetails(context),

                  const SizedBox(height: 20),

                  // Price and resale info
                  if (isResale || ticket.originalPrice != null)
                    _buildPriceSection(context, isResale),

                  if (isResale || ticket.originalPrice != null)
                    const SizedBox(height: 20),

                  // Action buttons
                  if (!isPast) _buildActionButtons(context, isResale),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, bool isResale, bool isPast) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    if (isResale) {
      backgroundColor = colorScheme.tertiaryContainer;
      textColor = colorScheme.onTertiaryContainer;
      icon = Icons.sell;
      text = 'Listed for Resale';
    } else {
      backgroundColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
      icon = Icons.history;
      text = 'Past Event';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBadge(BuildContext context, bool isPast, bool isUpcoming) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (ticket.eventStartDate == null) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.event,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    Color backgroundColor;
    Color textColor;

    if (isPast) {
      backgroundColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
    } else if (isUpcoming) {
      backgroundColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
    } else {
      backgroundColor = colorScheme.secondaryContainer;
      textColor = colorScheme.onSecondaryContainer;
    }

    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Text(
            DateFormat('MMM').format(ticket.eventStartDate!),
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('d').format(ticket.eventStartDate!),
            style: theme.textTheme.titleLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('EEE').format(ticket.eventStartDate!),
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo(BuildContext context, bool isResale) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ticket.eventName ?? 'Unknown Event',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        if (ticket.eventStartDate != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('h:mm a').format(ticket.eventStartDate!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],

        if (isResale && ticket.resellPrice != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.tertiary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sell,
                  size: 14,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Listed: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(ticket.resellPrice)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTicketTypeChip(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.secondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.confirmation_number,
            size: 14,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'Ticket',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDetails(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDetailItem(
              context,
              'Ticket ID',
              '#${ticket.ticketId}',
              Icons.tag,
            ),
          ),
          if (ticket.seat != null) ...[
            Container(
              width: 1,
              height: 40,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                context,
                'Seat',
                ticket.seat!,
                Icons.event_seat,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(BuildContext context, bool isResale) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.3),
            colorScheme.secondaryContainer.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          if (ticket.originalPrice != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Original Price',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  NumberFormat.currency(locale: 'en_US', symbol: '\$')
                      .format(ticket.originalPrice),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isResale ? TextDecoration.lineThrough : null,
                    color: isResale ? colorScheme.onSurfaceVariant : null,
                  ),
                ),
              ],
            ),

          if (isResale && ticket.resellPrice != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resale Price',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  NumberFormat.currency(locale: 'en_US', symbol: '\$')
                      .format(ticket.resellPrice),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Show profit/loss
            if (ticket.originalPrice != null) ...[
              const SizedBox(height: 8),
              _buildProfitLossIndicator(context),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildProfitLossIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final difference = ticket.resellPrice! - ticket.originalPrice!;
    final isProfit = difference > 0;

    final color = isProfit ? Colors.green : Colors.red;
    final icon = isProfit ? Icons.trending_up : Icons.trending_down;
    final text = isProfit ? 'Profit' : 'Loss';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$text: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(difference.abs())}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isResale) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isProcessing ? null : onDownload,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: colorScheme.primary),
              foregroundColor: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: isResale
              ? ElevatedButton.icon(
            onPressed: isProcessing ? null : onCancelResale,
            icon: isProcessing
                ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onTertiary,
              ),
            )
                : const Icon(Icons.cancel, size: 18),
            label: const Text('Cancel Resale'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.tertiary,
              foregroundColor: colorScheme.onTertiary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          )
              : ElevatedButton.icon(
            onPressed: isProcessing ? null : onResell,
            icon: isProcessing
                ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onSecondary,
              ),
            )
                : const Icon(Icons.sell, size: 18),
            label: const Text('List for Resale'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Color _getBorderColor(
      ColorScheme colorScheme,
      bool isResale,
      bool isPast,
      bool isUpcoming,
      ) {
    if (isResale) return colorScheme.tertiary.withOpacity(0.3);
    if (isPast) return colorScheme.outlineVariant;
    if (isUpcoming) return colorScheme.primary.withOpacity(0.3);
    return colorScheme.outlineVariant.withOpacity(0.3);
  }

  double _getBorderWidth(bool isResale, bool isPast, bool isUpcoming) {
    if (isResale || isUpcoming) return 1.5;
    return 1.0;
  }
}
