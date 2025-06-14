import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/models/ticket_model.dart';
import 'package:resellio/core/services/api_service.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';
import 'package:resellio/presentation/common_widgets/primary_button.dart';

// Convert to StatefulWidget
class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage>
    with SingleTickerProviderStateMixin {
  Future<List<TicketDetailsModel>>? _myTicketsFuture;

  late TabController _tabController;
  String _activeFilter = 'All';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Use addPostFrameCallback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyTickets();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _activeFilter = 'All';
            break;
          case 1:
            _activeFilter = 'Upcoming';
            break;
          case 2:
            _activeFilter = 'Resale';
            break;
        }
      });
      // The FutureBuilder will re-filter the list automatically
    }
  }

  void _loadMyTickets() {
    final apiService = context.read<ApiService>();
    
    setState(() {
      _isLoading = true;
      _myTicketsFuture = apiService.getMyTickets();
    });

    _myTicketsFuture!.whenComplete(() {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Simulate placing a ticket for resale
  void _resellTicket(TicketDetailsModel ticket) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController priceController = TextEditingController();
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Ticket listed for resale at \$${priceController.text}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('List for Resale'),
            ),
          ],
        );
      },
    );
  }

  // Simulate downloading a ticket
  void _downloadTicket(TicketDetailsModel ticket) {
    setState(() {
      _isLoading = true;
    });

    // Simulate download delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Simulate canceling resale
  void _cancelResale(TicketDetailsModel ticket) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Resale?'),
            content: const Text(
              'Are you sure you want to remove this ticket from resale?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ticket removed from resale'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: const Text('Yes, Cancel Resale'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PageLayout(
      title: 'My Tickets',
      body: Column(
        children: [
          // Tab Bar for filtering
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

          // Tickets List
          Expanded(
            child:
                (_isLoading || _myTicketsFuture == null)
                    ? const Center(child: CircularProgressIndicator())
                    : FutureBuilder<List<TicketDetailsModel>>(
                      future: _myTicketsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Could not load your tickets',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.error,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please try again',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                PrimaryButton(
                                  text: 'Retry',
                                  icon: Icons.refresh,
                                  onPressed: _loadMyTickets,
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  fullWidth: false,
                                  height: 40,
                                ),
                              ],
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tickets found',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Text(
                                    'Your purchased tickets will appear here',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final tickets = snapshot.data!;

                        // Filter tickets based on the selected tab
                        List<TicketDetailsModel> filteredTickets = [];
                        switch (_activeFilter) {
                          case 'All':
                            filteredTickets = tickets;
                            break;
                          case 'Upcoming':
                            filteredTickets =
                                tickets
                                    .where(
                                      (ticket) =>
                                          ticket.eventStartDate != null &&
                                          ticket.eventStartDate!.isAfter(
                                            DateTime.now(),
                                          ) &&
                                          ticket.resellPrice == null,
                                    )
                                    .toList();
                            break;
                          case 'Resale':
                            filteredTickets =
                                tickets
                                    .where(
                                      (ticket) => ticket.resellPrice != null,
                                    )
                                    .toList();
                            break;
                        }

                        if (filteredTickets.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _activeFilter == 'Resale'
                                      ? Icons.sell_outlined
                                      : Icons.confirmation_number_outlined,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _activeFilter == 'Resale'
                                      ? 'No tickets on resale'
                                      : _activeFilter == 'Upcoming'
                                      ? 'No upcoming tickets'
                                      : 'No tickets found',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTickets.length,
                          itemBuilder: (context, index) {
                            final ticket = filteredTickets[index];
                            final bool isResale = ticket.resellPrice != null;
                            final bool isPast =
                                ticket.eventStartDate != null &&
                                ticket.eventStartDate!.isBefore(DateTime.now());

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side:
                                    isPast
                                        ? BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        )
                                        : BorderSide.none,
                              ),
                              elevation: isPast ? 0 : 2,
                              child: InkWell(
                                onTap: () {
                                  // TODO: Navigate to ticket details
                                },
                                child: Column(
                                  children: [
                                    // Top status bar
                                    if (isResale || isPast)
                                      Container(
                                        width: double.infinity,
                                        color:
                                            isResale
                                                ? colorScheme.tertiary
                                                    .withOpacity(0.1)
                                                : Colors.grey.shade200,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isResale
                                                  ? Icons.sell
                                                  : Icons.history,
                                              size: 14,
                                              color:
                                                  isResale
                                                      ? colorScheme.tertiary
                                                      : Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isResale
                                                  ? 'On Resale'
                                                  : 'Past Event',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color:
                                                        isResale
                                                            ? colorScheme
                                                                .tertiary
                                                            : Colors
                                                                .grey
                                                                .shade600,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Main content
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Event Date Badge
                                          if (ticket.eventStartDate != null)
                                            Container(
                                              width: 50,
                                              decoration: BoxDecoration(
                                                color:
                                                    isPast
                                                        ? Colors.grey.shade200
                                                        : colorScheme
                                                            .primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 4,
                                                  ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    DateFormat('MMM').format(
                                                      ticket.eventStartDate!,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          isPast
                                                              ? Colors
                                                                  .grey
                                                                  .shade600
                                                              : colorScheme
                                                                  .onPrimaryContainer,
                                                    ),
                                                  ),
                                                  Text(
                                                    DateFormat('d').format(
                                                      ticket.eventStartDate!,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          isPast
                                                              ? Colors
                                                                  .grey
                                                                  .shade600
                                                              : colorScheme
                                                                  .onPrimaryContainer,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          const SizedBox(width: 16),

                                          // Ticket details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  ticket.eventName ??
                                                      'Unknown Event',
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            isPast
                                                                ? Colors
                                                                    .grey
                                                                    .shade600
                                                                : null,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                if (ticket.seat != null)
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.chair_outlined,
                                                        size: 14,
                                                        color:
                                                            colorScheme
                                                                .onSurfaceVariant,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Seat: ${ticket.seat}',
                                                        style: theme
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color:
                                                                  colorScheme
                                                                      .onSurfaceVariant,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                if (ticket.eventStartDate !=
                                                    null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.access_time,
                                                          size: 14,
                                                          color:
                                                              colorScheme
                                                                  .onSurfaceVariant,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          DateFormat(
                                                            'HH:mm',
                                                          ).format(
                                                            ticket
                                                                .eventStartDate!,
                                                          ),
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                color:
                                                                    colorScheme
                                                                        .onSurfaceVariant,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (ticket.resellPrice != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8,
                                                        ),
                                                    child: Text(
                                                      'Listed for: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(ticket.resellPrice)}',
                                                      style: theme
                                                          .textTheme
                                                          .labelMedium
                                                          ?.copyWith(
                                                            color:
                                                                colorScheme
                                                                    .tertiary,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Action buttons
                                    if (!isPast)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest
                                              .withOpacity(0.3),
                                          border: Border(
                                            top: BorderSide(
                                              color: colorScheme.outlineVariant
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                        child: OverflowBar(
                                          alignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed:
                                                  () => _downloadTicket(ticket),
                                              icon: const Icon(
                                                Icons.download_outlined,
                                                size: 18,
                                              ),
                                              label: const Text('Download'),
                                            ),
                                            if (isResale)
                                              TextButton.icon(
                                                onPressed:
                                                    () => _cancelResale(ticket),
                                                icon: const Icon(
                                                  Icons.cancel_outlined,
                                                  size: 18,
                                                ),
                                                label: const Text(
                                                  'Cancel Resale',
                                                ),
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      colorScheme.tertiary,
                                                ),
                                              )
                                            else
                                              TextButton.icon(
                                                onPressed:
                                                    () => _resellTicket(ticket),
                                                icon: const Icon(
                                                  Icons.sell_outlined,
                                                  size: 18,
                                                ),
                                                label: const Text('Resell'),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
