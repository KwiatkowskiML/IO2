import 'package:equatable/equatable.dart';
import 'package:resellio/core/models/event_model.dart';

abstract class EventBrowseState extends Equatable {
  const EventBrowseState();
  @override
  List<Object> get props => [];
}

class EventBrowseInitial extends EventBrowseState {}

class EventBrowseLoading extends EventBrowseState {}

class EventBrowseLoaded extends EventBrowseState {
  final List<Event> events;
  const EventBrowseLoaded(this.events);
  @override
  List<Object> get props => [events];
}

class EventBrowseError extends EventBrowseState {
  final String message;
  const EventBrowseError(this.message);
  @override
  List<Object> get props => [message];
}
