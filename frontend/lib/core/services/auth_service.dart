import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/common_widgets/adaptive_navigation.dart';

Map<String, dynamic>? tryDecodeJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final resp = utf8.decode(base64Url.decode(normalized));
    return json.decode(resp);
  } catch (e) {
    debugPrint('Error decoding JWT: $e');
    return null;
  }
}

class UserModel {
  final int userId;
  final String email;
  final String name;
  final UserRole role;
  final int roleId;

  UserModel(
      {required this.userId,
      required this.email,
      required this.name,
      required this.role,
      required this.roleId});

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
  final AuthRepository _authRepository;
  String? _token;
  UserModel? _user;

  AuthService(this._authRepository);

  bool get isLoggedIn => _token != null;
  UserModel? get user => _user;

  Future<void> login(String email, String password) async {
    final token = await _authRepository.login(email, password);
    _setTokenAndUser(token);
  }

  Future<void> registerCustomer(Map<String, dynamic> data) async {
    final token = await _authRepository.registerCustomer(data);
    _setTokenAndUser(token);
  }

  Future<void> registerOrganizer(Map<String, dynamic> data) async {
    final token = await _authRepository.registerOrganizer(data);
    _setTokenAndUser(token);
  }

  void _setTokenAndUser(String token) {
    _token = token;
    final jwtData = tryDecodeJwt(token);
    if (jwtData != null) {
      _user = UserModel.fromJwt(jwtData);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _token = null;
    _user = null;
    notifyListeners();
  }
}
