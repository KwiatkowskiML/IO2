import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/models/admin_model.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/admin/cubit/admin_dashboard_state.dart';
import 'package:resellio/core/models/models.dart';


class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final AdminRepository _adminRepository;

  AdminDashboardCubit(this._adminRepository) : super(AdminDashboardInitial());

  Future<void> loadDashboard() async {
    try {
      emit(AdminDashboardLoading());

      final results = await Future.wait([
        _adminRepository.getPendingOrganizers(),
        _adminRepository.getAllUsers(limit: 100),
        _adminRepository.getBannedUsers(),
        _adminRepository.getPendingEvents(),
      ]);

      emit(AdminDashboardLoaded(
        pendingOrganizers: results[0] as List<PendingOrganizer>,
        allUsers: results[1] as List<UserDetails>,
        bannedUsers: results[2] as List<UserDetails>,
        pendingEvents: results[3] as List<Event>,
      ));
    } on ApiException catch (e) {
      emit(AdminDashboardError(e.message));
    } catch (e) {
      emit(AdminDashboardError('An unexpected error occurred: $e'));
    }
  }

  Future<void> verifyOrganizer(int organizerId, bool approve) async {
    try {
      await _adminRepository.verifyOrganizer(organizerId, approve);
      await loadDashboard(); // Refresh data
    } on ApiException catch (e) {
      emit(AdminDashboardError(e.message));
      await Future.delayed(const Duration(seconds: 2));
      await loadDashboard(); // Still refresh to show current state
    }
  }

  Future<void> banUser(int userId) async {
    if (state is AdminDashboardLoaded) {
      emit(UserBanInProgress(userId));
    }

    try {
      await _adminRepository.banUser(userId);
      await loadDashboard();
    } on ApiException catch (e) {
      emit(AdminDashboardError(e.message));
      await Future.delayed(const Duration(seconds: 2));
      await loadDashboard();
    }
  }

  Future<void> unbanUser(int userId) async {
    if (state is AdminDashboardLoaded) {
      emit(UserUnbanInProgress(userId));
    }

    try {
      await _adminRepository.unbanUser(userId);
      await loadDashboard();
    } on ApiException catch (e) {
      emit(AdminDashboardError(e.message));
      await Future.delayed(const Duration(seconds: 2));
      await loadDashboard();
    }
  }

  Future<void> authorizeEvent(int eventId) async {
    if (state is AdminDashboardLoaded) {
      emit(EventAuthorizationInProgress(eventId));
    }

    try {
      await _adminRepository.authorizeEvent(eventId);
      await loadDashboard();
    } on ApiException catch (e) {
      emit(AdminDashboardError(e.message));
      await Future.delayed(const Duration(seconds: 2));
      await loadDashboard();
    }
  }

  Future<void> registerAdmin(Map<String, dynamic> adminData) async {
    try {
      emit(AdminDashboardLoading());
      await _adminRepository.registerAdmin(adminData);
      await loadDashboard();
    } on ApiException catch (e) {
      emit(AdminDashboardError(e.message));
    }
  }
}