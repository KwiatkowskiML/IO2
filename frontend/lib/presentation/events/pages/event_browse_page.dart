import 'package:flutter/material.dart';
import 'package:resellio/core/utils/responsive_layout.dart';
import 'package:resellio/presentation/events/widgets/event_card.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class EventBrowsePage extends StatelessWidget {
  const EventBrowsePage({super.key});

  // TODO: Replace with actual data fetching logic
  final List<Event> sampleEvents = const [
    Event(id: '1', name: 'Awesome Concert Gala Night Extravaganza', date: 'Apr 10, 2025', price: 50.00),
    Event(id: '2', name: 'Indie Music Fest', date: 'Apr 11, 2025', price: 55.00),
    Event(id: '3', name: 'Tech Conference 2025', date: 'Apr 12, 2025', price: 60.00),
    Event(id: '4', name: 'Art Exhibition Opening', date: 'Apr 13, 2025', price: 65.00),
    Event(id: '5', name: 'Charity Run Event', date: 'Apr 14, 2025', price: 70.00),
    Event(id: '6', name: 'Food Truck Festival Weekend', date: 'Apr 15, 2025', price: 75.00),
    Event(id: '7', name: 'Stand-up Comedy Special', date: 'Apr 16, 2025', price: 80.00),
    Event(id: '8', name: 'Movie Premiere Night', date: 'Apr 17, 2025', price: 85.00),
    Event(id: '9', name: 'Local Theater Play', date: 'Apr 18, 2025', price: 90.00),
    Event(id: '10', name: 'Rock Band Reunion Tour', date: 'Apr 19, 2025', price: 95.00),
  ];

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Discover Events',
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search Events',
          onPressed: () { /* TODO: Implement search */ },
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter Events',
          onPressed: () { /* TODO: Implement filter */ },
        ),
      ],
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: ResponsiveLayout.isMobile(context) ? 300 : 350,
          childAspectRatio: 0.70,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: sampleEvents.length,
        itemBuilder: (context, index) {
          final event = sampleEvents[index];
          return EventCard(
            event: event,
            onTap: () {

              print('Tapped event: ${event.name}');
            },
            onBuyPressed: () {

              print('Buy event: ${event.name}');
            },
          );
        },
      ),
    );
  }
}