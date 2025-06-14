import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/event_repository.dart';
import 'package:resellio/presentation/events/cubit/event_browse_state.dart';

class EventBrowseCubit extends Cubit<EventBrowseState> {
  final EventRepository _eventRepository;

  EventBrowseCubit(this._eventRepository) : super(EventBrowseInitial());

  Future<void> loadEvents() async {
    try {
      emit(EventBrowseLoading());
      final events = await _eventRepository.getEvents();
      emit(EventBrowseLoaded(events));
    } on ApiException catch (e) {
      emit(EventBrowseError(e.message));
    } catch (e) {
      emit(EventBrowseError('An unexpected error occurred: $e'));
    }
  }
}
