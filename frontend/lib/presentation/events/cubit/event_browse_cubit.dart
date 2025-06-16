import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/events/cubit/event_browse_state.dart';

class EventBrowseCubit extends Cubit<EventBrowseState> {
  final EventRepository _eventRepository;

  EventBrowseCubit(this._eventRepository) : super(EventBrowseInitial());

  Future<void> loadEvents({
    int page = 1,
    int limit = 20,
    String? search,
    String? location,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    double? minPrice,
    double? maxPrice,
    String? categories,
    String sortBy = 'start_date',
    String sortOrder = 'asc',
    bool reset = false,
  }) async {
    try {
      if (reset || state is! EventBrowseLoaded) {
        emit(EventBrowseLoading());
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (startDateFrom != null) {
        queryParams['start_date_from'] = startDateFrom.toIso8601String();
      }
      if (startDateTo != null) {
        queryParams['start_date_to'] = startDateTo.toIso8601String();
      }
      if (minPrice != null) {
        queryParams['min_price'] = minPrice;
      }
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice;
      }
      if (categories != null && categories.isNotEmpty) {
        queryParams['categories'] = categories;
      }

      final events = await _eventRepository.getEventsWithParams(queryParams);

      if (reset || state is! EventBrowseLoaded) {
        emit(EventBrowseLoaded(events));
      } else {
        final currentState = state as EventBrowseLoaded;
        emit(EventBrowseLoaded([...currentState.events, ...events]));
      }
    } on ApiException catch (e) {
      emit(EventBrowseError(e.message));
    } catch (e) {
      emit(EventBrowseError('An unexpected error occurred: $e'));
    }
  }

  Future<bool> loadMoreEvents({
    required int page,
    int limit = 20,
    String? search,
    String? location,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    double? minPrice,
    double? maxPrice,
    String? categories,
    String sortBy = 'start_date',
    String sortOrder = 'asc',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (startDateFrom != null) {
        queryParams['start_date_from'] = startDateFrom.toIso8601String();
      }
      if (startDateTo != null) {
        queryParams['start_date_to'] = startDateTo.toIso8601String();
      }
      if (minPrice != null) {
        queryParams['min_price'] = minPrice;
      }
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice;
      }
      if (categories != null && categories.isNotEmpty) {
        queryParams['categories'] = categories;
      }

      final newEvents = await _eventRepository.getEventsWithParams(queryParams);

      if (state is EventBrowseLoaded) {
        final currentState = state as EventBrowseLoaded;
        emit(EventBrowseLoaded([...currentState.events, ...newEvents]));
        return newEvents.length == limit; // Return true if there might be more data
      }

      return false;
    } catch (e) {
      // Don't emit error state for pagination failures, just return false
      return false;
    }
  }
}