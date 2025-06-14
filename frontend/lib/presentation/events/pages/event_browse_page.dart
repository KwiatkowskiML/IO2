import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/event_filter_model.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/utils/responsive_layout.dart';
import 'package:resellio/presentation/events/cubit/event_browse_cubit.dart';
import 'package:resellio/presentation/events/cubit/event_browse_state.dart';
import 'package:resellio/presentation/events/widgets/event_card.dart';
import 'package:resellio/presentation/events/widgets/event_filter_sheet.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class EventBrowsePage extends StatelessWidget {
  const EventBrowsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          EventBrowseCubit(context.read<EventRepository>())..loadEvents(),
      child: const _EventBrowseView(),
    );
  }
}

class _EventBrowseView extends StatefulWidget {
  const _EventBrowseView();

  @override
  State<_EventBrowseView> createState() => _EventBrowseViewState();
}

class _EventBrowseViewState extends State<_EventBrowseView> {
  EventFilterModel _currentFilters = const EventFilterModel();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Music',
    'Sports',
    'Arts',
    'Food',
    'Technology',
  ];

  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return EventFilterSheet(
          initialFilters: _currentFilters,
          onApplyFilters: (newFilters) {
            setState(() {
              _currentFilters = newFilters;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool filtersActive = _currentFilters.hasActiveFilters;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PageLayout(
      title: 'Discover Events',
      actions: [
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: filtersActive ? colorScheme.secondary : null,
          ),
          tooltip: 'Filter Events',
          onPressed: _showFilterSheet,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<EventBrowseCubit, EventBrowseState>(
              builder: (context, state) {
                if (state is EventBrowseLoading || state is EventBrowseInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is EventBrowseError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: colorScheme.error),
                        const SizedBox(height: 16),
                        Text('Failed to load events',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: colorScheme.error)),
                        const SizedBox(height: 8),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(state.message,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.read<EventBrowseCubit>().loadEvents(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is EventBrowseLoaded) {
                  if (state.events.isEmpty) {
                    return const Center(child: Text('No events found.'));
                  }
                  final events = state.events;

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent:
                            ResponsiveLayout.isMobile(context) ? 300 : 350,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return EventCard(event: events[index]);
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
