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

  Future<void> updateEvent(int eventId, Map<String, dynamic> eventData) async {
    try {
      emit(const EventFormSubmitting(locations: []));
      final updatedEvent =
          await _eventRepository.updateEvent(eventId, eventData);
      emit(EventFormSuccess(updatedEvent.id));
    } on ApiException catch (e) {
      emit(EventFormError(e.message));
    } catch (e) {
      emit(EventFormError('An unexpected error occurred: $e'));
    }
  }
}
