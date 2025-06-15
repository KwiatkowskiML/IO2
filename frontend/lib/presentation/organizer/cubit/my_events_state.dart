import 'package:equatable/equatable.dart';
import 'package:resellio/core/models/models.dart';

enum EventStatusFilter { all, active, pending, cancelled }

abstract class MyEventsState extends Equatable {
  const MyEventsState();
  @override
  List<Object> get props => [];
}

class MyEventsInitial extends MyEventsState {}

class MyEventsLoading extends MyEventsState {}

class MyEventsLoaded extends MyEventsState {
  final List<Event> allEvents;
  final EventStatusFilter activeFilter;

  const MyEventsLoaded({
    required this.allEvents,
    this.activeFilter = EventStatusFilter.all,
  });

  List<Event> get filteredEvents {
    switch (activeFilter) {
      case EventStatusFilter.active:
        return allEvents
            .where((event) => event.status.toLowerCase() == 'created')
            .toList();
      case EventStatusFilter.pending:
        return allEvents
            .where((event) => event.status.toLowerCase() == 'pending')
            .toList();
      case EventStatusFilter.cancelled:
        return allEvents
            .where((event) => event.status.toLowerCase() == 'cancelled')
            .toList();
      case EventStatusFilter.all:
      default:
        return allEvents;
    }
  }

  @override
  List<Object> get props => [allEvents, activeFilter];
}

class MyEventsError extends MyEventsState {
  final String message;
  const MyEventsError(this.message);
  @override
  List<Object> get props => [message];
}

class MyEventsActionInProgress extends MyEventsLoaded {
  const MyEventsActionInProgress({
    required super.allEvents,
    required super.activeFilter,
  });
}
