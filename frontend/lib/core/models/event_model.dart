class Event {
  final int id;
  final int organizerId;
  final String name;
  final String? description;
  final DateTime start;
  final DateTime end;
  final int? minimumAge;
  final String location;
  final String status;
  final List<String> category;
  final int totalTickets;
  final String? imageUrl;

  Event({
    required this.id,
    required this.organizerId,
    required this.name,
    this.description,
    required this.start,
    required this.end,
    this.minimumAge,
    required this.location,
    required this.status,
    required this.category,
    required this.totalTickets,
    this.imageUrl,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['event_id'],
      organizerId: json['organizer_id'],
      name: json['name'],
      description: json['description'],
      start: DateTime.parse(json['start_date']),
      end: DateTime.parse(json['end_date']),
      minimumAge: json['minimum_age'],
      location: json['location_name'] ?? 'Unknown Location',
      status: json['status'] ?? 'active',
      category: List<String>.from(json['categories'] ?? []),
      totalTickets: json['total_tickets'] ?? 0,
      imageUrl: json['imageUrl'] ??
          'https://picsum.photos/seed/${json['event_id']}/400/200',
    );
  }
}

class EventCreate {
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final int? minimumAge;
  final int locationId;
  final List<String> category;
  final int totalTickets;
  final double standardTicketPrice;
  final DateTime ticketSalesStartDateTime;

  EventCreate({
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    this.minimumAge,
    required this.locationId,
    required this.category,
    required this.totalTickets,
    required this.standardTicketPrice,
    required this.ticketSalesStartDateTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'minimum_age': minimumAge,
      'location_id': locationId,
      'category': category,
      'total_tickets': totalTickets,
      'standard_ticket_price': standardTicketPrice,
      'ticket_sales_start': ticketSalesStartDateTime.toIso8601String(),
    };
  }
}

class EventStatus {
  static const String created = 'created';
  static const String pending = 'pending';
  static const String cancelled = 'cancelled';
}
