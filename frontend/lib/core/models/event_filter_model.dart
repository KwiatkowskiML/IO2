class EventFilterModel {
  final String? name;
  final String? location;
  final DateTime? startDateFrom;
  final DateTime? startDateTo;

  const EventFilterModel({
    this.name,
    this.location,
    this.startDateFrom,
    this.startDateTo,
  });

  // Check if any filters are active
  bool get hasActiveFilters =>
      name != null ||
      location != null ||
      startDateFrom != null ||
      startDateTo != null;

  //copyWith method for immutability
  EventFilterModel copyWith({
    String? name,
    String? location,
    DateTime? startDateFrom,
    DateTime? startDateTo,
  }) {
    return EventFilterModel(
      name: name ?? this.name,
      location: location ?? this.location,
      startDateFrom: startDateFrom ?? this.startDateFrom,
      startDateTo: startDateTo ?? this.startDateTo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EventFilterModel &&
        other.name == name &&
        other.location == location &&
        other.startDateFrom == startDateFrom &&
        other.startDateTo == startDateTo;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        location.hashCode ^
        startDateFrom.hashCode ^
        startDateTo.hashCode;
  }

  // Convert to query parameters for API calls
  Map<String, String> toQueryParameters() {
    final Map<String, String> params = {};
    
    if (name != null && name!.isNotEmpty) {
      params['name'] = name!;
    }
    
    if (location != null && location!.isNotEmpty) {
      params['location'] = location!;
    }
    
    if (startDateFrom != null) {
      params['start_date_from'] = startDateFrom!.toIso8601String();
    }
    
    if (startDateTo != null) {
      params['start_date_to'] = startDateTo!.toIso8601String();
    }
    
    return params;
  }
}
