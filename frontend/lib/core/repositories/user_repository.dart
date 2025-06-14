import 'package:resellio/core/models/user_model.dart';
import 'package:resellio/core/network/api_client.dart';

abstract class UserRepository {
  Future<UserProfile> getUserProfile();
  Future<UserProfile> updateUserProfile(Map<String, dynamic> profileData);
}

class ApiUserRepository implements UserRepository {
  final ApiClient _apiClient;
  ApiUserRepository(this._apiClient);

  @override
  Future<UserProfile> getUserProfile() async {
    final data = await _apiClient.get('/user/me');
    return UserProfile.fromJson(data);
  }

  @override
  Future<UserProfile> updateUserProfile(
      Map<String, dynamic> profileData) async {
    final data = await _apiClient.put('/user/update-profile', data: profileData);
    return UserProfile.fromJson(data);
  }
}
