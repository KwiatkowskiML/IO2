import 'package:flutter/material.dart';

class EnhancedSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final bool filtersActive;
  final VoidCallback? onFilterTap;

  const EnhancedSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.searchQuery,
    required this.onSearchChanged,
    this.filtersActive = false,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    controller.clear();
                    onSearchChanged('');
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 0,
                ),
              ),
              style: theme.textTheme.bodyLarge,
              onSubmitted: onSearchChanged,
              onChanged: (value) {
                // Debounced search could be implemented here
                onSearchChanged(value);
              },
              textInputAction: TextInputAction.search,
            ),
          ),
          if (onFilterTap != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: onFilterTap,
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: filtersActive
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: filtersActive
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                tooltip: 'Advanced Filters',
              ),
            ),
        ],
      ),
    );
  }
}