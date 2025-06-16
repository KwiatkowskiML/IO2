import 'package:equatable/equatable.dart';
import 'package:resellio/core/models/models.dart';

abstract class EventFormState extends Equatable {
  const EventFormState();

  @override
  List<Object?> get props => [];
}

class EventFormInitial extends EventFormState {}

class EventFormPrerequisitesLoading extends EventFormState {}

class EventFormPrerequisitesLoaded extends EventFormState {
  final List<Location> locations;

  const EventFormPrerequisitesLoaded({required this.locations});

  @override
  List<Object?> get props => [locations];
}

class EventFormSubmitting extends EventFormPrerequisitesLoaded {
  const EventFormSubmitting({required super.locations});
}

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

class EventFormTicketTypesLoading extends EventFormState {}

class EventFormTicketTypesLoaded extends EventFormState {
  final List<TicketType> ticketTypes;

  const EventFormTicketTypesLoaded(this.ticketTypes);

  @override
  List<Object?> get props => [ticketTypes];
}

class EventFormTicketTypeCreated extends EventFormState {}

class EventFormTicketTypeDeleted extends EventFormState {}
