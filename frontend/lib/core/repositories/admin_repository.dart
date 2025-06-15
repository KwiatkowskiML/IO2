import 'package:resellio/core/models/admin_model.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/network/api_client.dart';

abstract class AdminRepository {
  Future<List<PendingOrganizer>> getPendingOrganizers();
  Future<List<UserDetails>> getAllUsers({
    int page = 1,
    int limit = 50,
    String? search,
    String? userType,
    bool? isActive,
    bool? isVerified,
  });
  Future<List<UserDetails>> getBannedUsers();
  Future<List<Event>> getPendingEvents();
  Future<void> verifyOrganizer(int organizerId, bool approve);
  Future<void> banUser(int userId);
  Future<void> unbanUser(int userId);
  Future<void> authorizeEvent(int eventId);
  Future<void> rejectEvent(int eventId);
  Future<String> registerAdmin(Map<String, dynamic> adminData);
  Future<UserDetails> getUserDetails(int userId);
  Future<AdminStats> getAdminStats();
}

class ApiAdminRepository implements AdminRepository {
  final ApiClient _apiClient;

  ApiAdminRepository(this._apiClient);

  @override
  Future<List<PendingOrganizer>> getPendingOrganizers() async {
    final data = await _apiClient.get('/auth/pending-organizers');
    return (data as List).map((e) => PendingOrganizer.fromJson(e)).toList();
  }

  @override
  Future<List<UserDetails>> getAllUsers({
    int page = 1,
    int limit = 50,
    String? search,
    String? userType,
    bool? isActive,
    bool? isVerified,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (userType != null) 'user_type': userType,
      if (isActive != null) 'is_active': isActive,
      if (isVerified != null) 'is_verified': isVerified,
    };

    final data = await _apiClient.get('/auth/users', queryParams: queryParams);
    return (data as List).map((e) => UserDetails.fromJson(e)).toList();
  }

  @override
  Future<List<UserDetails>> getBannedUsers() async {
    final data = await _apiClient.get('/auth/users', queryParams: {
      'is_active': false,
      'limit': 100,
    });
    return (data as List).map((e) => UserDetails.fromJson(e)).toList();
  }

  @override
  Future<List<Event>> getPendingEvents() async {
    final data = await _apiClient.get('/events', queryParams: {
      'status': 'pending',
      'limit': 100,
    });
    return (data as List).map((e) => Event.fromJson(e)).toList();
  }

  @override
  Future<void> verifyOrganizer(int organizerId, bool approve) async {
    await _apiClient.post(
      '/auth/verify-organizer',
      data: {'organizer_id': organizerId, 'approve': approve},
    );
  }

  @override
  Future<void> banUser(int userId) async {
    await _apiClient.post('/auth/ban-user/$userId');
  }

  @override
  Future<void> unbanUser(int userId) async {
    await _apiClient.post('/auth/unban-user/$userId');
  }

  @override
  Future<void> authorizeEvent(int eventId) async {
    await _apiClient.post('/events/authorize/$eventId');
  }

  @override
  Future<void> rejectEvent(int eventId) async {
    // Add reject event endpoint
    await _apiClient.post('/events/reject/$eventId');
  }

  @override
  Future<String> registerAdmin(Map<String, dynamic> adminData) async {
    final response = await _apiClient.post('/auth/register/admin', data: adminData);
    return response['token'] as String;
  }

  @override
  Future<UserDetails> getUserDetails(int userId) async {
    final data = await _apiClient.get('/auth/users/$userId');
    return UserDetails.fromJson(data);
  }

  @override
  Future<AdminStats> getAdminStats() async {
    final data = await _apiClient.get('/auth/users/stats');
    return AdminStats.fromJson(data);
  }
}