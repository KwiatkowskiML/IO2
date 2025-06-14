import 'package:resellio/core/network/api_client.dart';

abstract class UserRepository {
  Future<Map<String, dynamic>> getUserProfile();
  Future<void> updateUserProfile(Map<String, dynamic> profileData);
}

class ApiUserRepository implements UserRepository {
  final ApiClient _apiClient;
  ApiUserRepository(this._apiClient);

  @override
  Future<Map<String, dynamic>> getUserProfile() async {
    return await _apiClient.get('/user/me');
  }

  @override
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    await _apiClient.put('/user/update-profile', data: profileData);
  }
}
