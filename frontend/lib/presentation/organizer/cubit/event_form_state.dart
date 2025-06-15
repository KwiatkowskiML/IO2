import 'package:equatable/equatable.dart';

abstract class EventFormState extends Equatable {
  const EventFormState();
  @override
  List<Object?> get props => [];
}

class EventFormInitial extends EventFormState {}

class EventFormSubmitting extends EventFormState {}

class EventFormSuccess extends EventFormState {
  final int eventId;
  const EventFormSuccess(this.eventId);
  @override
  List<Object?> get props => [eventId];
}

class EventFormError extends EventFormState {
  final String message;
  const EventFormError(this.message);
  @override
  List<Object?> get props => [message];
}
