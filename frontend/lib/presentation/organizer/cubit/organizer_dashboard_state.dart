import 'package:equatable/equatable.dart';
import 'package:resellio/core/models/models.dart';

abstract class OrganizerDashboardState extends Equatable {
  const OrganizerDashboardState();
  @override
  List<Object?> get props => [];
}

class OrganizerDashboardInitial extends OrganizerDashboardState {}

class OrganizerDashboardLoading extends OrganizerDashboardState {}

class OrganizerDashboardLoaded extends OrganizerDashboardState {
  final List<Event> events;
  const OrganizerDashboardLoaded(this.events);
  @override
  List<Object?> get props => [events];
}

class OrganizerDashboardError extends OrganizerDashboardState {
  final String message;
  const OrganizerDashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

class OrganizerDashboardUnverified extends OrganizerDashboardState {
  final String message;
  const OrganizerDashboardUnverified(this.message);
  @override
  List<Object?> get props => [message];
}
