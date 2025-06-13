class EventFilterModel {
  final String? name;
  final String? location;
  final DateTime? startDateFrom;
  final DateTime? startDateTo;
  final double? minPrice;
  final double? maxPrice;

  const EventFilterModel({
    this.name,
    this.location,
    this.startDateFrom,
    this.startDateTo,
    this.minPrice,
    this.maxPrice,
  });

  // Check if any filters are active
  bool get hasActiveFilters =>
      name != null ||
      location != null ||
      startDateFrom != null ||
      startDateTo != null ||
      minPrice != null ||
      maxPrice != null;

  //copyWith method for immutability
  EventFilterModel copyWith({
    String? name,
    String? location,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    double? minPrice,
    double? maxPrice,
  }) {
    return EventFilterModel(
      name: name ?? this.name,
      location: location ?? this.location,
      startDateFrom: startDateFrom ?? this.startDateFrom,
      startDateTo: startDateTo ?? this.startDateTo,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EventFilterModel &&
        other.name == name &&
        other.location == location &&
        other.startDateFrom == startDateFrom &&
        other.startDateTo == startDateTo &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        location.hashCode ^
        startDateFrom.hashCode ^
        startDateTo.hashCode ^
        minPrice.hashCode ^
        maxPrice.hashCode;
  }
}
