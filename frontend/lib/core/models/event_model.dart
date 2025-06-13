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
  final String? imageUrl; // Added for UI

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
      // Use a placeholder image if none is provided
      imageUrl:
          json['imageUrl'] ??
          'https://picsum.photos/seed/${json['event_id']}/400/200',
    );
  }
}
