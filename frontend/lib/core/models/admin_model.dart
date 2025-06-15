class PendingOrganizer {
  final int userId;
  final String email;
  final String firstName;
  final String lastName;
  final int organizerId;
  final String companyName;
  final bool isVerified;

  PendingOrganizer({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.organizerId,
    required this.companyName,
    required this.isVerified,
  });

  factory PendingOrganizer.fromJson(Map<String, dynamic> json) {
    return PendingOrganizer(
      userId: json['user_id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      organizerId: json['organizer_id'],
      companyName: json['company_name'],
      isVerified: json['is_verified'],
    );
  }
}

class UserDetails {
  final int userId;
  final String email;
  final String firstName;
  final String lastName;
  final String userType;
  final bool isActive;

  UserDetails({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
    required this.isActive,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      userId: json['user_id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      userType: json['user_type'],
      isActive: json['is_active'],
    );
  }
}
