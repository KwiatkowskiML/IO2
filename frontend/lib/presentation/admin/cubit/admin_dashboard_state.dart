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

  const AdminDashboardLoaded(
      {required this.pendingOrganizers, required this.allUsers});
  @override
  List<Object?> get props => [pendingOrganizers, allUsers];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  const AdminDashboardError(this.message);
  @override
  List<Object?> get props => [message];
}
