import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final int userId;
  final String email;
  final String? login;
  final String firstName;
  final String lastName;
  final String userType;
  final bool isActive;

  const UserProfile({
    required this.userId,
    required this.email,
    this.login,
    required this.firstName,
    required this.lastName,
    required this.userType,
    required this.isActive,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final userType = json['user_type'] as String? ?? 'customer';
    if (userType == 'organizer') {
      return OrganizerProfile.fromJson(json);
    }
    // TODO: Add other types like Admin if they have special fields.
    return UserProfile(
      userId: json['user_id'],
      email: json['email'],
      login: json['login'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      userType: json['user_type'],
      isActive: json['is_active'],
    );
  }

  @override
  List<Object?> get props =>
      [userId, email, login, firstName, lastName, userType, isActive];
}

class OrganizerProfile extends UserProfile {
  final int organizerId;
  final String companyName;
  final bool isVerified;

  const OrganizerProfile({
    required super.userId,
    required super.email,
    super.login,
    required super.firstName,
    required super.lastName,
    required super.userType,
    required super.isActive,
    required this.organizerId,
    required this.companyName,
    required this.isVerified,
  });

  factory OrganizerProfile.fromJson(Map<String, dynamic> json) {
    return OrganizerProfile(
      userId: json['user_id'],
      email: json['email'],
      login: json['login'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      userType: json['user_type'],
      isActive: json['is_active'],
      organizerId: json['organizer_id'],
      companyName: json['company_name'],
      isVerified: json['is_verified'],
    );
  }

  @override
  List<Object?> get props =>
      super.props..addAll([organizerId, companyName, isVerified]);
}
