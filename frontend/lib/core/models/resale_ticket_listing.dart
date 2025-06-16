class ResaleTicketListing {
  final int ticketId;
  final double originalPrice;
  final double resellPrice;
  final String eventName;
  final DateTime eventDate;
  final String venueName;
  final String ticketTypeDescription;
  final String? seat;

  ResaleTicketListing({
    required this.ticketId,
    required this.originalPrice,
    required this.resellPrice,
    required this.eventName,
    required this.eventDate,
    required this.venueName,
    required this.ticketTypeDescription,
    this.seat,
  });

  factory ResaleTicketListing.fromJson(Map<String, dynamic> json) {
    return ResaleTicketListing(
      ticketId: json['ticket_id'],
      originalPrice: (json['original_price'] as num).toDouble(),
      resellPrice: (json['resell_price'] as num).toDouble(),
      eventName: json['event_name'],
      eventDate: DateTime.parse(json['event_date']),
      venueName: json['venue_name'],
      ticketTypeDescription:
          json['ticket_type_description'] ?? 'Standard Ticket',
      seat: json['seat'],
    );
  }
}
