import 'package:equatable/equatable.dart';

abstract class OrganizerStatsState extends Equatable {
  const OrganizerStatsState();

  @override
  List<Object> get props => [];
}

class OrganizerStatsInitial extends OrganizerStatsState {}

class OrganizerStatsLoading extends OrganizerStatsState {}

class OrganizerStatsLoaded extends OrganizerStatsState {
  final int totalEvents;
  final int activeEvents;
  final int pendingEvents;
  final int totalTickets;

  const OrganizerStatsLoaded({
    required this.totalEvents,
    required this.activeEvents,
    required this.pendingEvents,
    required this.totalTickets,
  });

  @override
  List<Object> get props =>
      [totalEvents, activeEvents, pendingEvents, totalTickets];
}

class OrganizerStatsError extends OrganizerStatsState {
  final String message;

  const OrganizerStatsError(this.message);

  @override
  List<Object> get props => [message];
}
