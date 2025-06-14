import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/admin_model.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final AdminRepository _adminRepository;

  AdminDashboardCubit(this._adminRepository) : super(AdminDashboardInitial());

  Future<void> loadDashboard() async {
    try {
      emit(AdminDashboardLoading());
      final pending = await _adminRepository.getPendingOrganizers();
      final users = await _adminRepository.getAllUsers();
      emit(AdminDashboardLoaded(pendingOrganizers: pending, allUsers: users));
    } on ApiException catch (e) {
      emit(AdminDashboardError(e.message));
    } catch (e) {
      emit(AdminDashboardError('An unexpected error occurred: $e'));
    }
  }

  Future<void> verifyOrganizer(int organizerId, bool approve) async {
    try {
      await _adminRepository.verifyOrganizer(organizerId, approve);
      await loadDashboard();
    } on ApiException catch (_) {
      // TODO: Potentially emit an error to the UI
      await loadDashboard(); // Refresh data even on failure
    }
  }
}
