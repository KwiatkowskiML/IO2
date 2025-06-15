class Location {
  final int locationId;
  final String name;
  final String address;
  final String city;
  final String country;

  Location({
    required this.locationId,
    required this.name,
    required this.address,
    required this.city,
    required this.country,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      locationId: json['location_id'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
    );
  }

  @override
  String toString() {
    return name;
  }
}
