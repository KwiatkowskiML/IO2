import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/user_model.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/event_repository.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/organizer/cubit/organizer_stats_state.dart';

class OrganizerStatsCubit extends Cubit<OrganizerStatsState> {
  final EventRepository _eventRepository;
  final AuthService _authService;

  OrganizerStatsCubit(this._eventRepository, this._authService)
      : super(OrganizerStatsInitial());

  Future<void> loadStatistics() async {
    try {
      emit(OrganizerStatsLoading());

      final profile = _authService.detailedProfile;
      if (profile is! OrganizerProfile) {
        emit(const OrganizerStatsError("User is not a valid organizer."));
        return;
      }

      final events =
          await _eventRepository.getOrganizerEvents(profile.organizerId);

      final totalEvents = events.length;
      final activeEvents =
          events.where((e) => e.status.toLowerCase() == 'created').length;
      final pendingEvents =
          events.where((e) => e.status.toLowerCase() == 'pending').length;
      final totalTickets = events.fold(0, (sum, e) => sum + e.totalTickets);

      emit(OrganizerStatsLoaded(
        totalEvents: totalEvents,
        activeEvents: activeEvents,
        pendingEvents: pendingEvents,
        totalTickets: totalTickets,
      ));
    } on ApiException catch (e) {
      emit(OrganizerStatsError(e.message));
    } catch (e) {
      emit(OrganizerStatsError("An unexpected error occurred: $e"));
    }
  }
}
