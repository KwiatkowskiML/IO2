import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/cart/cubit/cart_cubit.dart';
import 'package:resellio/presentation/common_widgets/primary_button.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class EventDetailsPage extends StatefulWidget {
  final Event? event;
  final int? eventId;

  const EventDetailsPage({super.key, this.event, this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  late Future<List<TicketType>> _ticketTypesFuture;

  @override
  void initState() {
    super.initState();
    _loadTicketTypes();
  }

  void _loadTicketTypes() {
    final eventRepository = context.read<EventRepository>();
    final id = widget.event?.id ?? widget.eventId;
    if (id != null) {
      setState(() {
        _ticketTypesFuture = eventRepository.getTicketTypesForEvent(id);
      });
    }
  }

  void _addToCart(TicketType ticketType) {
    if (ticketType.typeId != null) {
      context.read<CartCubit>().addItem(ticketType.typeId!, 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ticketType.description} added to cart!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.event == null) {
      return const Scaffold(body: Center(child: Text("Loading Event...")));
    }

    final event = widget.event!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final DateFormat dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');

    return PageLayout(
      title: event.name,
      showBackButton: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    event.imageUrl!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(event.name,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow(
                icon: Icons.calendar_today,
                text: dateFormat.format(event.start),
                context: context),
            const SizedBox(height: 8),
            _buildInfoRow(
                icon: Icons.access_time,
                text:
                    '${timeFormat.format(event.start)} - ${timeFormat.format(event.end)}',
                context: context),
            const SizedBox(height: 8),
            _buildInfoRow(
                icon: Icons.location_on,
                text: event.location,
                context: context),
            const SizedBox(height: 24),
            Text('Tickets',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<TicketType>>(
              future: _ticketTypesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No tickets available for this event.'));
                }

                final ticketTypes = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ticketTypes.length,
                  itemBuilder: (context, index) {
                    final ticketType = ticketTypes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      ticketType.description ??
                                          'Standard Ticket',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                      '\$${ticketType.price.toStringAsFixed(2)}',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                          color: colorScheme.primary)),
                                ],
                              ),
                            ),
                            PrimaryButton(
                              text: 'Add to Cart',
                              onPressed: () => _addToCart(ticketType),
                              fullWidth: false,
                              height: 40,
                              icon: Icons.add_shopping_cart,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      {required IconData icon,
      required String text,
      required BuildContext context}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
      ],
    );
  }
}
