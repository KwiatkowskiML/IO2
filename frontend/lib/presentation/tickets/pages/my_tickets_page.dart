import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/ticket_model.dart';
import 'package:resellio/core/repositories/ticket_repository.dart';
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
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<MyTicketsCubit>().loadTickets(),
                          child: const Text('Retry'),
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
                      final bool isProcessing = state is TicketUpdateInProgress &&
                          state.processingTicketId == ticket.ticketId;
                      return _TicketCard(
                        ticket: ticket,
                        isProcessing: isProcessing,
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

class _TicketCard extends StatelessWidget {
  final TicketDetailsModel ticket;
  final bool isProcessing;

  const _TicketCard({required this.ticket, required this.isProcessing});

  void _resellTicketDialog(BuildContext context) {
    final cubit = context.read<MyTicketsCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final priceController = TextEditingController();
        return AlertDialog(
          title: const Text('Set Resale Price'),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Price (USD)',
              prefixText: '\$',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final price = double.tryParse(priceController.text);
                if (price != null && price > 0) {
                  cubit.listForResale(ticket.ticketId, price);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('List for Resale'),
            ),
          ],
        );
      },
    );
  }

  void _cancelResaleDialog(BuildContext context) {
    final cubit = context.read<MyTicketsCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Resale?'),
        content:
            const Text('Are you sure you want to remove this ticket from resale?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () {
              cubit.cancelResale(ticket.ticketId);
              Navigator.pop(dialogContext);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isResale = ticket.resellPrice != null;
    final bool isPast = ticket.eventStartDate != null &&
        ticket.eventStartDate!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPast
            ? BorderSide(color: Colors.grey.shade300, width: 1)
            : BorderSide.none,
      ),
      elevation: isPast ? 0 : 2,
      child: Column(
        children: [
          if (isProcessing) const LinearProgressIndicator(),
          if (isResale || isPast)
            Container(
              width: double.infinity,
              color: isResale
                  ? colorScheme.tertiary.withOpacity(0.1)
                  : Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
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
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isResale
                          ? colorScheme.tertiary
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ticket.eventStartDate != null)
                  Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: isPast
                          ? Colors.grey.shade200
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('MMM').format(ticket.eventStartDate!),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isPast
                                  ? Colors.grey.shade600
                                  : colorScheme.onPrimaryContainer),
                        ),
                        Text(
                          DateFormat('d').format(ticket.eventStartDate!),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isPast
                                  ? Colors.grey.shade600
                                  : colorScheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.eventName ?? 'Unknown Event',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPast ? Colors.grey.shade600 : null,
                        ),
                      ),
                      if (ticket.resellPrice != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Listed for: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(ticket.resellPrice)}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isPast)
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: Border(
                  top: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.5)),
                ),
              ),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: isProcessing ? null : () {},
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download'),
                  ),
                  if (isResale)
                    TextButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _cancelResaleDialog(context),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancel Resale'),
                      style: TextButton.styleFrom(
                          foregroundColor: colorScheme.tertiary),
                    )
                  else
                    TextButton.icon(
                      onPressed:
                          isProcessing ? null : () => _resellTicketDialog(context),
                      icon: const Icon(Icons.sell_outlined, size: 18),
                      label: const Text('Resell'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
