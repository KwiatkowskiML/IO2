import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/organizer/cubit/event_form_state.dart';

class EventFormCubit extends Cubit<EventFormState> {
  final EventRepository _eventRepository;

  EventFormCubit(this._eventRepository) : super(EventFormInitial());

  Future<void> loadPrerequisites() async {
    try {
      emit(EventFormPrerequisitesLoading());
      final locations = await _eventRepository.getLocations();
      emit(EventFormPrerequisitesLoaded(locations: locations));
    } on ApiException catch (e) {
      emit(EventFormError(e.message));
    } catch (e) {
      emit(EventFormError('An unexpected error occurred: $e'));
    }
  }

  Future<void> createEvent(EventCreate eventData) async {
    if (state is! EventFormPrerequisitesLoaded) return;
    final loadedState = state as EventFormPrerequisitesLoaded;

    try {
      emit(EventFormSubmitting(locations: loadedState.locations));
      final newEvent = await _eventRepository.createEvent(eventData);
      emit(EventFormSuccess(newEvent.id));
    } on ApiException catch (e) {
      emit(EventFormError(e.message));
      // Revert to loaded state on error to keep the form usable
      emit(EventFormPrerequisitesLoaded(locations: loadedState.locations));
    } catch (e) {
      emit(EventFormError('An unexpected error occurred: $e'));
      emit(EventFormPrerequisitesLoaded(locations: loadedState.locations));
    }
  }

  Future<void> loadExistingTicketTypes(int eventId) async {
    try {
      emit(EventFormTicketTypesLoading());
      final ticketTypes = await _eventRepository.getTicketTypesForEvent(eventId);
      emit(EventFormTicketTypesLoaded(ticketTypes));
    } on ApiException catch (e) {
      emit(EventFormError('Failed to load ticket types: ${e.message}'));
    } catch (e) {
      emit(EventFormError('Failed to load ticket types: $e'));
    }
  }

  /// Simple event update without ticket types
  Future<void> updateEvent(int eventId, Map<String, dynamic> eventData) async {
    try {
      emit(const EventFormSubmitting(locations: []));
      final updatedEvent = await _eventRepository.updateEvent(eventId, eventData);
      emit(EventFormSuccess(updatedEvent.id));
    } on ApiException catch (e) {
      emit(EventFormError(e.message));
    } catch (e) {
      emit(EventFormError('An unexpected error occurred: $e'));
    }
  }

  /// Update event details only - ticket types are managed separately
  Future<void> updateEventWithTicketTypes(
    int eventId,
    Map<String, dynamic> eventData,
    List<TicketType> newTicketTypes
  ) async {
    try {
      emit(const EventFormSubmitting(locations: []));

      // 1. Update the event details first
      await _eventRepository.updateEvent(eventId, eventData);

      // 2. Create only NEW ticket types (no deletion/updating of existing ones)
      for (final ticketType in newTicketTypes) {
        if (ticketType.typeId == null) {
          await _createSingleTicketType(eventId, ticketType);
          print('Created new ticket type: ${ticketType.description}');
        }
      }

      emit(EventFormSuccess(eventId));
    } on ApiException catch (e) {
      emit(EventFormError(e.message));
    } catch (e) {
      emit(EventFormError('Failed to update event: $e'));
    }
  }

  bool canDeleteTicketType(TicketType ticketType) {
    if (ticketType.availableFrom == null) return false;
    return ticketType.availableFrom!.isAfter(DateTime.now());
  }

  Future<void> deleteTicketType(int typeId, TicketType ticketType) async {
    try {
      // Check if deletion is allowed
      if (!canDeleteTicketType(ticketType)) {
        emit(EventFormError(
          'Cannot delete ticket type "${ticketType.description ?? ''}" - sales have already started or no availability date set.'
        ));
        return;
      }

      await _eventRepository.deleteTicketType(typeId);
      emit(EventFormTicketTypeDeleted());

      if (ticketType.eventId != null) {
        await loadExistingTicketTypes(ticketType.eventId);
      }
    } on ApiException catch (e) {
      emit(EventFormError(e.message));
    } catch (e) {
      emit(EventFormError('Failed to delete ticket type: $e'));
    }
  }

  Future<void> _createSingleTicketType(int eventId, TicketType ticketType) async {
    if (ticketType.availableFrom == null) {
      throw Exception('Available from date is required for ticket type: ${ticketType.description}');
    }

    await _eventRepository.createTicketType({
      'event_id': eventId,
      'description': ticketType.description ?? '',
      'max_count': ticketType.maxCount,
      'price': ticketType.price,
      'currency': ticketType.currency,
      'available_from': ticketType.availableFrom!.toIso8601String(),
    });
  }

  Future<void> createTicketType(int eventId, TicketType ticketType) async {
    try {
      await _createSingleTicketType(eventId, ticketType);
      emit(EventFormTicketTypeCreated());

      await loadExistingTicketTypes(eventId);
    } on ApiException catch (e) {
      emit(EventFormError(e.message));
    } catch (e) {
      emit(EventFormError('Failed to create ticket type: $e'));
    }
  }
}
