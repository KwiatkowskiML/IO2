import 'package:resellio/core/network/api_client.dart';

abstract class AdminRepository {
  Future<List<dynamic>> getPendingOrganizers();
  Future<List<dynamic>> getAllUsers();
  Future<void> verifyOrganizer(int organizerId, bool approve);
  Future<void> banUser(int userId);
  Future<void> unbanUser(int userId);
}

class ApiAdminRepository implements AdminRepository {
  final ApiClient _apiClient;
  ApiAdminRepository(this._apiClient);

  @override
  Future<List<dynamic>> getPendingOrganizers() async {
    return await _apiClient.get('/auth/pending-organizers');
  }

  @override
  Future<List<dynamic>> getAllUsers() async {
    // TODO: This is a mocked endpoint as it's missing in the backend spec
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'user_id': 1,
        'email': 'customer1@example.com',
        'first_name': 'Alice',
        'last_name': 'Customer',
        'user_type': 'customer',
        'is_active': true,
      },
      {
        'user_id': 2,
        'email': 'organizer1@example.com',
        'first_name': 'Bob',
        'last_name': 'Organizer',
        'user_type': 'organizer',
        'is_active': true,
      },
    ];
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
}
