import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/organizer/cubit/event_form_state.dart';

class EventFormCubit extends Cubit<EventFormState> {
  final EventRepository _eventRepository;

  EventFormCubit(this._eventRepository) : super(EventFormInitial());

  Future<void> createEvent(EventCreate eventData) async {
    try {
      emit(EventFormSubmitting());
      final newEvent = await _eventRepository.createEvent(eventData);
      emit(EventFormSuccess(newEvent.id));
    } on ApiException catch (e) {
      emit(EventFormError(e.message));
    } catch (e) {
      emit(EventFormError('An unexpected error occurred: $e'));
    }
  }

  Future<void> updateEvent(int eventId, EventCreate eventData) async {
    try {
      emit(EventFormSubmitting());
      final updatedEvent = await _eventRepository.updateEvent(eventId, eventData);
      emit(EventFormSuccess(updatedEvent.id));
    } on ApiException catch (e) {
      emit(EventFormError(e.message));
    } catch (e) {
      emit(EventFormError('An unexpected error occurred: $e'));
    }
  }
}
