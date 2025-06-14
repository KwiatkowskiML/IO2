import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/common_widgets/dialogs.dart';
import 'package:resellio/presentation/common_widgets/list_item_card.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/tickets/cubit/my_tickets_cubit.dart';
import 'package:resellio/presentation/tickets/cubit/my_tickets_state.dart';

class MyTicketsPage extends StatelessWidget {
  const MyTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MyTicketsCubit(context.read<TicketRepository>())..loadTickets(),
      child: const _MyTicketsView(),
    );
  }
}

class _MyTicketsView extends StatefulWidget {
  const _MyTicketsView();

  @override
  State<_MyTicketsView> createState() => _MyTicketsViewState();
}

class _MyTicketsViewState extends State<_MyTicketsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final filter = TicketFilter.values[_tabController.index];
      context.read<MyTicketsCubit>().setFilter(filter);
    }
  }

  void _resellTicketDialog(BuildContext context, TicketDetailsModel ticket) async {
    final priceString = await showInputDialog(
      context: context,
      title: 'Set Resale Price',
      label: 'Price (USD)',
      prefixText: '\$ ',
      keyboardType: TextInputType.number,
      confirmText: 'List for Resale',
    );

    if (priceString != null) {
      final price = double.tryParse(priceString);
      if (price != null && price > 0) {
        context.read<MyTicketsCubit>().listForResale(ticket.ticketId, price);
      }
    }
  }

  void _cancelResaleDialog(BuildContext context, TicketDetailsModel ticket) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Cancel Resale?',
      content:
          const Text('Are you sure you want to remove this ticket from resale?'),
      confirmText: 'Yes, Cancel',
    );
    if (confirmed == true) {
      context.read<MyTicketsCubit>().cancelResale(ticket.ticketId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PageLayout(
      title: 'My Tickets',
      body: Column(
        children: [
          Container(
            color: colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'All Tickets'),
                Tab(text: 'Upcoming'),
                Tab(text: 'On Resale'),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<MyTicketsCubit, MyTicketsState>(
              listener: (context, state) {
                if (state is MyTicketsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is MyTicketsLoading || state is MyTicketsInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MyTicketsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: colorScheme.error),
                        const SizedBox(height: 16),
                        Text('Failed to load tickets',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: colorScheme.error)),
                        const SizedBox(height: 8),
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.read<MyTicketsCubit>().loadTickets(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is MyTicketsLoaded) {
                  final tickets = state.filteredTickets;
                  if (tickets.isEmpty) {
                    return const Center(child: Text('No tickets found.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      final bool isProcessing =
                          state is TicketUpdateInProgress &&
                              state.processingTicketId == ticket.ticketId;
                      final bool isResale = ticket.resellPrice != null;
                      final bool isPast = ticket.eventStartDate != null &&
                          ticket.eventStartDate!.isBefore(DateTime.now());

                      return ListItemCard(
                        isProcessing: isProcessing,
                        isDimmed: isPast,
                        topContent: (isResale || isPast)
                            ? Container(
                                width: double.infinity,
                                color: isResale
                                    ? colorScheme.tertiary.withOpacity(0.1)
                                    : Colors.grey.shade200,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(
                                      isResale ? Icons.sell : Icons.history,
                                      size: 14,
                                      color: isResale
                                          ? colorScheme.tertiary
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isResale ? 'On Resale' : 'Past Event',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: isResale
                                            ? colorScheme.tertiary
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                        leadingWidget: ticket.eventStartDate != null
                            ? Container(
                                width: 50,
                                decoration: BoxDecoration(
                                  color: isPast
                                      ? Colors.grey.shade200
                                      : colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                child: Column(
                                  children: [
                                    Text(
                                      DateFormat('MMM')
                                          .format(ticket.eventStartDate!),
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                              color: isPast
                                                  ? Colors.grey.shade600
                                                  : colorScheme
                                                      .onPrimaryContainer),
                                    ),
                                    Text(
                                      DateFormat('d')
                                          .format(ticket.eventStartDate!),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              color: isPast
                                                  ? Colors.grey.shade600
                                                  : colorScheme
                                                      .onPrimaryContainer),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                        title: Text(ticket.eventName ?? 'Unknown Event'),
                        subtitle: ticket.resellPrice != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Listed for: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(ticket.resellPrice)}',
                                  style:
                                      theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.tertiary,
                                  ),
                                ),
                              )
                            : null,
                        bottomContent: !isPast
                            ? OverflowBar(
                                alignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: isProcessing ? null : () {},
                                    icon: const Icon(Icons.download_outlined,
                                        size: 18),
                                    label: const Text('Download'),
                                  ),
                                  if (isResale)
                                    TextButton.icon(
                                      onPressed: isProcessing
                                          ? null
                                          : () => _cancelResaleDialog(
                                              context, ticket),
                                      icon: const Icon(Icons.cancel_outlined,
                                          size: 18),
                                      label: const Text('Cancel Resale'),
                                      style: TextButton.styleFrom(
                                          foregroundColor:
                                              colorScheme.tertiary),
                                    )
                                  else
                                    TextButton.icon(
                                      onPressed: isProcessing
                                          ? null
                                          : () => _resellTicketDialog(
                                              context, ticket),
                                      icon: const Icon(Icons.sell_outlined,
                                          size: 18),
                                      label: const Text('Resell'),
                                    ),
                                ],
                              )
                            : null,
                      );
                    },
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
