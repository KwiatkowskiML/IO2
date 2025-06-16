import 'package:flutter/material.dart';

class ListItemCard extends StatelessWidget {
  final Widget? leadingWidget;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailingWidget;
  final Widget? bottomContent;
  final Widget? topContent;
  final VoidCallback? onTap;
  final bool isProcessing;
  final bool isDimmed;

  const ListItemCard({
    super.key,
    this.leadingWidget,
    required this.title,
    this.subtitle,
    this.trailingWidget,
    this.bottomContent,
    this.topContent,
    this.onTap,
    this.isProcessing = false,
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDimmed
            ? BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))
            : BorderSide.none,
      ),
      elevation: isDimmed ? 0 : 2,
      child: Column(
        children: [
          if (isProcessing) const LinearProgressIndicator(),
          if (topContent != null) topContent!,
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leadingWidget != null) ...[
                    leadingWidget!,
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle(
                          style: (theme.textTheme.titleMedium ??
                                  const TextStyle())
                              .copyWith(
                            color: isDimmed
                                ? colorScheme.onSurface.withOpacity(0.6)
                                : null,
                          ),
                          child: title,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          DefaultTextStyle(
                            style: (theme.textTheme.bodyMedium ??
                                    const TextStyle())
                                .copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            child: subtitle!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailingWidget != null) ...[
                    const SizedBox(width: 16),
                    trailingWidget!,
                  ],
                ],
              ),
            ),
          ),
          if (bottomContent != null)
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: Border(
                  top: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.5)),
                ),
              ),
              child: bottomContent,
            ),
        ],
      ),
    );
  }
}
