import 'package:flutter/material.dart';


class Event {
  final String id;
  final String name;
  final String date;
  final double price;
  final String? imageUrl;

  const Event({
    required this.id,
    required this.name,
    required this.date,
    required this.price,
    this.imageUrl,
  });
}


class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onBuyPressed;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onBuyPressed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Expanded(
              flex: 5,
              child: Container(
                color: Colors.grey.shade800,
                width: double.infinity,
                child: event.imageUrl != null
                    ? Image.network(event.imageUrl!, fit: BoxFit.cover)
                    : Icon(
                  Icons.event,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),


            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.date,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    Row( // Price and Buy Button
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${event.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (onBuyPressed != null)
                          ElevatedButton(
                            onPressed: onBuyPressed,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Buy'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}