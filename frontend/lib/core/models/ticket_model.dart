class TicketType {
  final int? typeId;
  final int eventId;
  final String? description;
  final int maxCount;
  final double price;
  final String currency;

  TicketType({
    this.typeId,
    required this.eventId,
    this.description,
    required this.maxCount,
    required this.price,
    required this.currency,
  });

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      typeId: json['type_id'],
      eventId: json['event_id'],
      description: json['description'],
      maxCount: json['max_count'],
      // Price can be int or double from JSON
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }
}

class TicketDetailsModel {
  final int ticketId;
  final int? typeId;
  final String? seat;
  final int? ownerId;
  final double? resellPrice;

  // These fields are not in the base model but can be added for convenience
  final String? eventName;
  final DateTime? eventStartDate;

  TicketDetailsModel({
    required this.ticketId,
    this.typeId,
    this.seat,
    this.ownerId,
    this.resellPrice,
    this.eventName,
    this.eventStartDate,
  });

  factory TicketDetailsModel.fromJson(Map<String, dynamic> json) {
    return TicketDetailsModel(
      ticketId: json['ticket_id'],
      typeId: json['type_id'],
      seat: json['seat'],
      ownerId: json['owner_id'],
      resellPrice:
          json['resell_price'] != null
              ? (json['resell_price'] as num).toDouble()
              : null,
      // Handle extra mocked data
      eventName: json['eventName'],
      eventStartDate:
          json['eventStartDate'] != null
              ? DateTime.parse(json['eventStartDate'])
              : null,
    );
  }
}
