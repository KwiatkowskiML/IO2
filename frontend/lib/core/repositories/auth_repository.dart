import 'package:dio/dio.dart';
import 'package:resellio/core/network/api_client.dart';

abstract class AuthRepository {
  Future<String> login(String email, String password);
  Future<String> registerCustomer(Map<String, dynamic> data);
  Future<String> registerOrganizer(Map<String, dynamic> data);
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
      return response['token'];
    } else {
      throw Exception('Login failed: ${response['message']}');
    }
  }

  @override
  Future<String> registerCustomer(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/auth/register/customer', data: data);
    return response['token'];
  }

  @override
  Future<String> registerOrganizer(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/auth/register/organizer', data: data);
    return response['token'];
  }
}
