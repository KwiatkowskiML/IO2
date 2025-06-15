import 'package:equatable/equatable.dart';
import 'package:resellio/core/models/models.dart';

abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();
  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final List<PendingOrganizer> pendingOrganizers;
  final List<UserDetails> allUsers;
  final List<UserDetails> bannedUsers;
  final List<Event> pendingEvents;

  const AdminDashboardLoaded({
    required this.pendingOrganizers,
    required this.allUsers,
    required this.bannedUsers,
    required this.pendingEvents,
  });

  @override
  List<Object?> get props => [pendingOrganizers, allUsers, bannedUsers, pendingEvents];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  const AdminDashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

// Specific states for user management
class UserManagementLoading extends AdminDashboardState {}

class UserBanInProgress extends AdminDashboardState {
  final int userId;
  const UserBanInProgress(this.userId);
  @override
  List<Object?> get props => [userId];
}

class UserUnbanInProgress extends AdminDashboardState {
  final int userId;
  const UserUnbanInProgress(this.userId);
  @override
  List<Object?> get props => [userId];
}

// Event authorization states
class EventAuthorizationInProgress extends AdminDashboardState {
  final int eventId;
  const EventAuthorizationInProgress(this.eventId);
  @override
  List<Object?> get props => [eventId];
}