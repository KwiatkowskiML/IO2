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

class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final int bannedUsers;
  final int totalCustomers;
  final int totalOrganizers;
  final int totalAdmins;
  final int verifiedOrganizers;
  final int pendingOrganizers;
  final int pendingEvents;
  final int totalEvents;

  AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.bannedUsers,
    required this.totalCustomers,
    required this.totalOrganizers,
    required this.totalAdmins,
    required this.verifiedOrganizers,
    required this.pendingOrganizers,
    required this.pendingEvents,
    required this.totalEvents,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final usersByType = json['users_by_type'] ?? {};
    final organizerStats = json['organizer_stats'] ?? {};

    return AdminStats(
      totalUsers: json['total_users'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      bannedUsers: json['banned_users'] ?? 0,
      totalCustomers: usersByType['customers'] ?? 0,
      totalOrganizers: usersByType['organizers'] ?? 0,
      totalAdmins: usersByType['administrators'] ?? 0,
      verifiedOrganizers: organizerStats['verified'] ?? 0,
      pendingOrganizers: organizerStats['pending'] ?? 0,
      pendingEvents: json['pending_events'] ?? 0,
      totalEvents: json['total_events'] ?? 0,
    );
  }
}