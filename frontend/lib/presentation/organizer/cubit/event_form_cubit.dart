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

  Future<void> updateEventWithTicketTypes(
    int eventId,
    Map<String, dynamic> eventData,
    List<TicketType> additionalTicketTypes
  ) async {
    try {
      emit(const EventFormSubmitting(locations: []));

      // 1. Update the event details first
      await _eventRepository.updateEvent(eventId, eventData);

      // 2. Get existing ticket types to compare
      final existingTicketTypes = await _eventRepository.getTicketTypesForEvent(eventId);
      final existingAdditionalTypes = existingTicketTypes
          .where((t) => (t.description ?? '') != "Standard Ticket")
          .toList();

      // 3. Delete removed ticket types
      for (final existing in existingAdditionalTypes) {
        final stillExists = additionalTicketTypes.any((t) =>
          t.typeId != null && t.typeId == existing.typeId);

        if (!stillExists && existing.typeId != null) {
          await _eventRepository.deleteTicketType(existing.typeId!);
          print('Deleted ticket type: ${existing.description}');
        }
      }

      // 4. Create or update ticket types
      for (final ticketType in additionalTicketTypes) {
        if (ticketType.typeId == null) {
          // Create new ticket type
          await _createSingleTicketType(eventId, ticketType);
          print('Created new ticket type: ${ticketType.description}');
        } else {
          // Update existing ticket type
          await _updateSingleTicketType(ticketType);
          print('Updated ticket type: ${ticketType.description}');
        }
      }

      emit(EventFormSuccess(eventId));
    } on ApiException catch (e) {
      emit(EventFormError(e.message));
    } catch (e) {
      emit(EventFormError('Failed to update event: $e'));
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

  Future<void> _updateSingleTicketType(TicketType ticketType) async {
    if (ticketType.typeId == null) {
      throw Exception('Cannot update ticket type without ID');
    }

    if (ticketType.availableFrom == null) {
      throw Exception('Available from date is required for ticket type: ${ticketType.description}');
    }

    await _eventRepository.updateTicketType(ticketType.typeId!, {
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
    } on ApiException catch (e) {
      emit(EventFormError(e.message));
    } catch (e) {
      emit(EventFormError('Failed to create ticket type: $e'));
    }
  }

  Future<void> updateTicketType(TicketType ticketType) async {
    try {
      await _updateSingleTicketType(ticketType);
      emit(EventFormTicketTypeUpdated());
    } on ApiException catch (e) {
      emit(EventFormError(e.message));
    } catch (e) {
      emit(EventFormError('Failed to update ticket type: $e'));
    }
  }

  Future<void> deleteTicketType(int typeId) async {
    try {
      await _eventRepository.deleteTicketType(typeId);
      emit(EventFormTicketTypeDeleted());
    } on ApiException catch (e) {
      emit(EventFormError(e.message));
    } catch (e) {
      emit(EventFormError('Failed to delete ticket type: $e'));
    }
  }
}
