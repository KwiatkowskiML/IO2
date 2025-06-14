import 'package:flutter_bloc/flutter_bloc.dart';
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
    final organizerId = _authService.user?.roleId;
    if (organizerId == null) {
      emit(const OrganizerDashboardError("User is not a valid organizer."));
      return;
    }

    try {
      emit(OrganizerDashboardLoading());
      final events = await _eventRepository.getOrganizerEvents(organizerId);
      emit(OrganizerDashboardLoaded(events));
    } on ApiException catch (e) {
      emit(OrganizerDashboardError(e.message));
    }
  }
}
