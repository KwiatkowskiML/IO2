import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:resellio/core/services/api_service.dart';
import 'package:resellio/presentation/common_widgets/adaptive_navigation.dart';

// --- JWT Decoding Helper ---
Map<String, dynamic>? tryDecodeJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final resp = utf8.decode(base64Url.decode(normalized));
    return json.decode(resp);
  } catch (e) {
    debugPrint('Error decoding JWT: $e');
    return null;
  }
}

// --- User Model ---
class UserModel {
  final int userId;
  final String email;
  final String name;
  final UserRole role;
  final int roleId;

  UserModel({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.roleId,
  });

  factory UserModel.fromJwt(Map<String, dynamic> jwtData) {
    UserRole role;
    switch (jwtData['role']) {
      case 'organizer':
        role = UserRole.organizer;
        break;
      case 'administrator':
        role = UserRole.admin;
        break;
      default:
        role = UserRole.customer;
    }

    return UserModel(
      userId: jwtData['user_id'],
      email: jwtData['sub'],
      name: jwtData['name'] ?? 'User',
      role: role,
      roleId: jwtData['role_id'],
    );
  }
}

class AuthService extends ChangeNotifier {
  final ApiService _apiService;
  String? _token;
  UserModel? _user;

  AuthService(this._apiService);

  bool get isLoggedIn => _token != null;
  UserModel? get user => _user;

  Future<void> login(String email, String password) async {
    try {
      final token = await _apiService.login(email, password);
      _setTokenAndUser(token);
    } catch (e) {
      // Rethrow to be caught in the UI
      rethrow;
    }
  }

  Future<void> registerCustomer(Map<String, dynamic> data) async {
    try {
      final token = await _apiService.registerCustomer(data);
      _setTokenAndUser(token);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerOrganizer(Map<String, dynamic> data) async {
    try {
      final token = await _apiService.registerOrganizer(data);
      _setTokenAndUser(token);
    } catch (e) {
      rethrow;
    }
  }

  void _setTokenAndUser(String token) {
    _token = token;
    _apiService.setAuthToken(token);

    final jwtData = tryDecodeJwt(token);
    if (jwtData != null) {
      _user = UserModel.fromJwt(jwtData);
    }
    notifyListeners();
  }

  void logout() {
    _token = null;
    _user = null;
    _apiService.setAuthToken(null);
    notifyListeners();
  }
}
