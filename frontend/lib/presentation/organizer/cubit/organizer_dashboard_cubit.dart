import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/organizer/cubit/organizer_dashboard_state.dart';

class OrganizerDashboardCubit extends Cubit<OrganizerDashboardState> {
  final EventRepository _eventRepository;
  final AuthService _authService;

  OrganizerDashboardCubit(this._eventRepository, this._authService)
      : super(OrganizerDashboardInitial());

  Future<void> loadDashboard() async {
    final profile = _authService.detailedProfile;

    if (profile is! OrganizerProfile) {
      emit(const OrganizerDashboardError("User is not a valid organizer."));
      return;
    }

    if (!profile.isVerified) {
      emit(OrganizerDashboardUnverified(
          'Your account is pending verification.'));
      return;
    }

    final organizerId = profile.organizerId;

    try {
      emit(OrganizerDashboardLoading());
      final events = await _eventRepository.getOrganizerEvents(organizerId);
      emit(OrganizerDashboardLoaded(events));
    } on ApiException catch (e) {
      emit(OrganizerDashboardError(e.message));
    } catch (e) {
      emit(OrganizerDashboardError("An unexpected error occurred: $e"));
    }
  }

  Future<void> cancelEvent(int eventId) async {
    try {
      await _eventRepository.cancelEvent(eventId);
      await loadDashboard();
    } on ApiException catch (e) {
      emit(OrganizerDashboardError(e.message));
    } catch (e) {
      emit(OrganizerDashboardError("Failed to cancel event."));
    }
  }

  Future<void> notifyParticipants(int eventId, String message) async {
    try {
      await _eventRepository.notifyParticipants(eventId, message);
    } on ApiException catch (e) {
      emit(OrganizerDashboardError(e.message));
    } catch (e) {
      emit(OrganizerDashboardError("Failed to send notification."));
    }
  }
}
