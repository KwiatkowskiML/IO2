import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/common_widgets/dialogs.dart';
import 'package:resellio/presentation/common_widgets/empty_state_widget.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/tickets/cubit/my_tickets_cubit.dart';
import 'package:resellio/presentation/tickets/cubit/my_tickets_state.dart';
import 'package:resellio/presentation/tickets/widgets/ticket_card.dart';
import 'package:resellio/presentation/tickets/widgets/ticket_stats_header.dart';
import 'package:resellio/presentation/tickets/widgets/ticket_filter_tabs.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket listed for resale at \$${price.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid price'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelResaleDialog(BuildContext context, TicketDetailsModel ticket) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Cancel Resale?',
      content: const Text('Are you sure you want to remove this ticket from resale?'),
      confirmText: 'Yes, Cancel',
    );
    if (confirmed == true) {
      context.read<MyTicketsCubit>().cancelResale(ticket.ticketId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket removed from resale'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _downloadTicket(TicketDetailsModel ticket) {
    // Placeholder for download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Downloading ticket for ${ticket.eventName ?? "Unknown Event"}'),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  List<TicketDetailsModel> _sortTicketsByDate(List<TicketDetailsModel> tickets) {
    final sortedTickets = List<TicketDetailsModel>.from(tickets);
    sortedTickets.sort((a, b) {
      final dateA = a.eventStartDate ?? DateTime(1970);
      final dateB = b.eventStartDate ?? DateTime(1970);
      return dateA.compareTo(dateB);
    });
    return sortedTickets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PageLayout(
      title: 'My Tickets',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Tickets',
          onPressed: () => context.read<MyTicketsCubit>().loadTickets(),
        ),
      ],
      body: Column(
        children: [
          // Enhanced header with stats and tabs
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.surface,
                ],
              ),
            ),
            child: Column(
              children: [
                BlocBuilder<MyTicketsCubit, MyTicketsState>(
                  builder: (context, state) {
                    if (state is MyTicketsLoaded) {
                      return TicketStatsHeader(tickets: state.allTickets);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                TicketFilterTabs(
                  tabController: _tabController,
                  onTabChange: _handleTabChange,
                ),
              ],
            ),
          ),

          // Tickets content
          Expanded(
            child: BlocConsumer<MyTicketsCubit, MyTicketsState>(
              listener: (context, state) {
                if (state is MyTicketsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Error: ${state.message}')),
                        ],
                      ),
                      backgroundColor: colorScheme.error,
                      behavior: SnackBarBehavior.floating,
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
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline,
                              size: 64,
                              color: colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Failed to Load Tickets',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.read<MyTicketsCubit>().loadTickets(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is MyTicketsLoaded) {
                  final sortedTickets = _sortTicketsByDate(state.filteredTickets);

                  if (sortedTickets.isEmpty) {
                    String emptyMessage = 'No tickets found';
                    String emptyDetails = 'Your tickets will appear here once you make a purchase.';

                    switch (state.activeFilter) {
                      case TicketFilter.upcoming:
                        emptyMessage = 'No upcoming events';
                        emptyDetails = 'You don\'t have any tickets for future events.';
                        break;
                      case TicketFilter.resale:
                        emptyMessage = 'No tickets on resale';
                        emptyDetails = 'You haven\'t listed any tickets for resale yet.';
                        break;
                      default:
                        break;
                    }

                    return EmptyStateWidget(
                      icon: Icons.confirmation_number_outlined,
                      message: emptyMessage,
                      details: emptyDetails,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => context.read<MyTicketsCubit>().loadTickets(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = sortedTickets[index];
                        final bool isProcessing =
                            state is TicketUpdateInProgress &&
                                state.processingTicketId == ticket.ticketId;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TicketCard(
                            ticket: ticket,
                            isProcessing: isProcessing,
                            onResell: () => _resellTicketDialog(context, ticket),
                            onCancelResale: () => _cancelResaleDialog(context, ticket),
                            onDownload: () => _downloadTicket(ticket),
                          ),
                        );
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