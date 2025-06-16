import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/utils/jwt_decoder.dart';
import 'package:resellio/presentation/common_widgets/adaptive_navigation.dart';


class AuthService extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  String? _token;
  UserModel? _user;
  UserProfile? _detailedProfile;

  static const String _tokenKey = 'resellio_auth_token';

  AuthService(this._authRepository, this._userRepository) {
    _loadStoredToken();
  }

  bool get isLoggedIn => _token != null;
  UserModel? get user => _user;
  UserProfile? get detailedProfile => _detailedProfile;

  Future<void> _loadStoredToken() async {
    try {
      final storedToken = html.window.localStorage[_tokenKey];
      if (storedToken != null && storedToken.isNotEmpty) {
        final jwtData = tryDecodeJwt(storedToken);
        if (jwtData != null) {
          final exp = jwtData['exp'];
          if (exp != null) {
            final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
            if (expiryDate.isAfter(DateTime.now())) {
              _token = storedToken;
              _user = UserModel.fromJwt(jwtData);

              try {
                _detailedProfile = await _userRepository.getUserProfile();
              } catch (e) {
                debugPrint("Failed to fetch detailed profile on token restore: $e");
              }

              notifyListeners();
              return;
            }
          }
        }

        await _clearStoredToken();
      }
    } catch (e) {
      debugPrint("Error loading stored token: $e");
      await _clearStoredToken();
    }
  }

  void _storeToken(String token) {
    html.window.localStorage[_tokenKey] = token;
  }

  Future<void> _clearStoredToken() async {
    html.window.localStorage.remove(_tokenKey);
    _token = null;
    _user = null;
    _detailedProfile = null;
  }

  Future<void> _setTokenAndUser(String token) async {
    _token = token;
    _storeToken(token);
    _detailedProfile = null;

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

  Future<String> registerCustomer(Map<String, dynamic> data) async {
    final message = await _authRepository.registerCustomer(data);
    return message;
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
    await _clearStoredToken();
    notifyListeners();
  }

  Future<void> refreshUserData() async {
    if (_token != null && _user != null) {
      try {
        _detailedProfile = await _userRepository.getUserProfile();
        notifyListeners();
      } catch (e) {
        debugPrint("Failed to refresh user data: $e");
        // If refresh fails due to invalid token, logout
        if (e.toString().contains('401') || e.toString().contains('403')) {
          await logout();
        }
      }
    }
  }
}
