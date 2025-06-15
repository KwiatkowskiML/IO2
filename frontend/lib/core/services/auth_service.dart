import 'package:flutter/material.dart';
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/utils/jwt_decoder.dart';
import 'package:resellio/presentation/common_widgets/adaptive_navigation.dart';

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
  final UserRepository _userRepository;
  String? _token;
  UserModel? _user;
  UserProfile? _detailedProfile;

  AuthService(this._authRepository, this._userRepository);

  bool get isLoggedIn => _token != null;
  UserModel? get user => _user;
  UserProfile? get detailedProfile => _detailedProfile;

  Future<void> _setTokenAndUser(String token) async {
    _token = token;
    _detailedProfile = null; // Clear old profile data
    final jwtData = tryDecodeJwt(token);
    if (jwtData != null) {
      _user = UserModel.fromJwt(jwtData);
      try {
        _detailedProfile = await _userRepository.getUserProfile();
      } catch (e) {
        debugPrint("Failed to fetch detailed profile on login: $e");
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final token = await _authRepository.login(email, password);
    await _setTokenAndUser(token);
  }

  Future<void> registerCustomer(Map<String, dynamic> data) async {
    final token = await _authRepository.registerCustomer(data);
    await _setTokenAndUser(token);
  }

  Future<void> registerOrganizer(Map<String, dynamic> data) async {
    final token = await _authRepository.registerOrganizer(data);
    await _setTokenAndUser(token);
  }

  void updateDetailedProfile(UserProfile profile) {
    if (_detailedProfile != profile) {
      _detailedProfile = profile;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _token = null;
    _user = null;
    _detailedProfile = null;
    notifyListeners();
  }
}
