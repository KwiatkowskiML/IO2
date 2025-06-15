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

  /// Load users with backend filtering and pagination
  Future<List<UserDetails>> loadUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? userType,
    bool? isActive,
    bool? isVerified,
  }) async {
    try {
      return await _adminRepository.getAllUsers(
        page: page,
        limit: limit,
        search: search,
        userType: userType,
        isActive: isActive,
        isVerified: isVerified,
      );
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
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
      // Check if user can be banned
      final canBan = await _adminRepository.canBanUser(userId);
      if (!canBan) {
        final user = await _adminRepository.getUserById(userId);
        throw ApiException(
            'Cannot ban ${user.firstName} ${user.lastName}: Administrator accounts are protected from banning'
        );
      }

      await _adminRepository.banUser(userId);
      await loadDashboard();
    } on ApiException catch (e) {
      emit(AdminDashboardError(e.message));
      await Future.delayed(const Duration(seconds: 3));
      await loadDashboard();
    } catch (e) {
      emit(AdminDashboardError('Failed to ban user: $e'));
      await Future.delayed(const Duration(seconds: 3));
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

  Future<void> rejectEvent(int eventId) async {
    if (state is AdminDashboardLoaded) {
      emit(EventAuthorizationInProgress(eventId));
    }

    try {
      await _adminRepository.rejectEvent(eventId);
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

  /// Get admin statistics
  Future<AdminStats> getAdminStats() async {
    try {
      return await _adminRepository.getAdminStats();
    } catch (e) {
      // Fallback calculation from loaded data
      if (state is AdminDashboardLoaded) {
        final loadedState = state as AdminDashboardLoaded;
        return AdminStats(
          totalUsers: loadedState.allUsers.length,
          activeUsers: loadedState.allUsers.where((u) => u.isActive).length,
          bannedUsers: loadedState.bannedUsers.length,
          totalCustomers: loadedState.allUsers.where((u) => u.userType == 'customer').length,
          totalOrganizers: loadedState.allUsers.where((u) => u.userType == 'organizer').length,
          totalAdmins: loadedState.allUsers.where((u) => u.userType == 'administrator').length,
          verifiedOrganizers: loadedState.pendingOrganizers.where((o) => o.isVerified).length,
          pendingOrganizers: loadedState.pendingOrganizers.length,
          pendingEvents: loadedState.pendingEvents.length,
          totalEvents: 0, // This would need to come from another source
        );
      }
      throw Exception('Failed to get admin stats: $e');
    }
  }
}