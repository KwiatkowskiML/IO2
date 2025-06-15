import 'package:dio/dio.dart';
import 'package:resellio/core/network/api_client.dart';

abstract class AuthRepository {
  Future<String> login(String email, String password);
  Future<String> registerCustomer(Map<String, dynamic> data);
  Future<String> registerOrganizer(Map<String, dynamic> data);
  Future<void> logout();
}

class ApiAuthRepository implements AuthRepository {
  final ApiClient _apiClient;

  ApiAuthRepository(this._apiClient);

  @override
  Future<String> login(String email, String password) async {
    final response = await _apiClient.post(
      '/auth/token',
      data: {'username': email, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (response['token'] != null && response['token'].isNotEmpty) {
      final token = response['token'] as String;
      _apiClient.setAuthToken(token);
      return token;
    } else {
      throw Exception('Login failed: ${response['message']}');
    }
  }

  @override
  Future<String> registerCustomer(Map<String, dynamic> data) async {
    final response =
        await _apiClient.post('/auth/register/customer', data: data);
     if (response != null && response['message'] is String) {
      return response['message'] as String;
    } else {
      throw Exception('Customer registration failed or returned an unexpected response.');
    }
  }

  @override
  Future<String> registerOrganizer(Map<String, dynamic> data) async {
    final response =
        await _apiClient.post('/auth/register/organizer', data: data);
    final token = response['token'] as String;
    _apiClient.setAuthToken(token);
    return token;
  }

  @override
  Future<void> logout() async {
    _apiClient.setAuthToken(null);
  }
}
