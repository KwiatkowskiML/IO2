class TicketType {
  final int? typeId;
  final int eventId;
  final String? description;
  final int maxCount;
  final double price;
  final String currency;
  final DateTime? availableFrom; // Added this field

  TicketType({
    this.typeId,
    required this.eventId,
    this.description,
    required this.maxCount,
    required this.price,
    required this.currency,
    this.availableFrom, // Added this parameter
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
      // Parse availableFrom field
      availableFrom: json['available_from'] != null
        ? DateTime.parse(json['available_from'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type_id': typeId,
      'event_id': eventId,
      'description': description,
      'max_count': maxCount,
      'price': price,
      'currency': currency,
      'available_from': availableFrom?.toIso8601String(), // Added this field
    };
  }

  // Add copyWith method for easier updates
  TicketType copyWith({
    int? typeId,
    int? eventId,
    String? description,
    int? maxCount,
    double? price,
    String? currency,
    DateTime? availableFrom,
  }) {
    return TicketType(
      typeId: typeId ?? this.typeId,
      eventId: eventId ?? this.eventId,
      description: description ?? this.description,
      maxCount: maxCount ?? this.maxCount,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      availableFrom: availableFrom ?? this.availableFrom,
    );
  }

  @override
  String toString() {
    return 'TicketType{typeId: $typeId, eventId: $eventId, description: $description, maxCount: $maxCount, price: $price, currency: $currency, availableFrom: $availableFrom}';
  }
}

class TicketDetailsModel {
  final int ticketId;
  final int? typeId;
  final String? seat;
  final int? ownerId;
  final double? resellPrice;
  final double? originalPrice; // The price the user paid for the ticket

  // These fields are not in the base model but can be added for convenience
  final String? eventName;
  final DateTime? eventStartDate;

  // Add ticket type details for convenience
  final String? ticketTypeDescription;
  final DateTime? ticketAvailableFrom; // Added this field

  TicketDetailsModel({
    required this.ticketId,
    this.typeId,
    this.seat,
    this.ownerId,
    this.resellPrice,
    this.originalPrice,
    this.eventName,
    this.eventStartDate,
    this.ticketTypeDescription,
    this.ticketAvailableFrom, // Added this parameter
  });

  factory TicketDetailsModel.fromJson(Map<String, dynamic> json) {
    return TicketDetailsModel(
      ticketId: json['ticket_id'],
      typeId: json['type_id'],
      seat: json['seat'],
      ownerId: json['owner_id'],
      resellPrice: json['resell_price'] != null
          ? (json['resell_price'] as num).toDouble()
          : null,
      originalPrice: json['original_price'] != null
          ? (json['original_price'] as num).toDouble()
          : null,
      // Handle both snake_case (from backend) and camelCase (from mock data)
      eventName: json['event_name'] ?? json['eventName'],
      eventStartDate: json['event_start_date'] != null
          ? DateTime.parse(json['event_start_date'])
          : json['eventStartDate'] != null
              ? DateTime.parse(json['eventStartDate'])
              : null,
      // Add ticket type description and available from
      ticketTypeDescription: json['ticket_type_description'],
      ticketAvailableFrom: json['ticket_available_from'] != null
          ? DateTime.parse(json['ticket_available_from'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'type_id': typeId,
      'seat': seat,
      'owner_id': ownerId,
      'resell_price': resellPrice,
      'original_price': originalPrice,
      'event_name': eventName,
      'event_start_date': eventStartDate?.toIso8601String(),
      'ticket_type_description': ticketTypeDescription,
      'ticket_available_from': ticketAvailableFrom?.toIso8601String(),
    };
  }
}
