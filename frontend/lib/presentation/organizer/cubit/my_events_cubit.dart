import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/user_model.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/organizer/cubit/my_events_state.dart';

class MyEventsCubit extends Cubit<MyEventsState> {
  final EventRepository _eventRepository;
  final AuthService _authService;

  MyEventsCubit(this._eventRepository, this._authService)
      : super(MyEventsInitial());

  Future<void> loadEvents() async {
    try {
      emit(MyEventsLoading());

      final profile = _authService.detailedProfile;
      if (profile is! OrganizerProfile) {
        emit(const MyEventsError("User is not a valid organizer."));
        return;
      }

      final events =
          await _eventRepository.getOrganizerEvents(profile.organizerId);
      emit(MyEventsLoaded(allEvents: events));
    } on ApiException catch (e) {
      emit(MyEventsError(e.message));
    } catch (e) {
      emit(MyEventsError("An unexpected error occurred: $e"));
    }
  }

  void setFilter(EventStatusFilter filter) {
    if (state is MyEventsLoaded) {
      final loadedState = state as MyEventsLoaded;
      emit(MyEventsLoaded(
        allEvents: loadedState.allEvents,
        activeFilter: filter,
      ));
    }
  }

  Future<void> cancelEvent(int eventId) async {
    if (state is! MyEventsLoaded) return;
    final loadedState = state as MyEventsLoaded;
    emit(MyEventsActionInProgress(
        allEvents: loadedState.allEvents,
        activeFilter: loadedState.activeFilter));
    try {
      await _eventRepository.cancelEvent(eventId);
      await loadEvents();
    } on ApiException catch (e) {
      emit(MyEventsError(e.message));
    } catch (e) {
      emit(const MyEventsError("Failed to cancel event."));
    }
  }

  Future<void> notifyParticipants(int eventId, String message) async {
    if (state is! MyEventsLoaded) return;
    final loadedState = state as MyEventsLoaded;
    emit(MyEventsActionInProgress(
        allEvents: loadedState.allEvents,
        activeFilter: loadedState.activeFilter));
    try {
      await _eventRepository.notifyParticipants(eventId, message);
      emit(MyEventsLoaded(
          allEvents: loadedState.allEvents,
          activeFilter: loadedState.activeFilter));
    } on ApiException catch (e) {
      emit(MyEventsError(e.message));
    } catch (e) {
      emit(const MyEventsError("Failed to send notification."));
    }
  }
}
