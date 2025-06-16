import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/services/storage_service.dart';

import 'dart:html' as html show window;

class ApiClient {
  final Dio _dio;
  String? _authToken;
  static const String _tokenKey = 'resellio_auth_token';

  ApiClient(String baseUrl) : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.interceptors.add(_createInterceptor());

    if (kIsWeb) {
      _loadStoredToken();
    }
  }

  void _loadStoredToken() {
    if (kIsWeb) {
      _authToken = StorageService.instance.getItem(_tokenKey);
    }
  }

  void setAuthToken(String? token) {
    _authToken = token;
    if (kIsWeb) {
      if (token != null) {
        StorageService.instance.setItem(_tokenKey, token);
      } else {
        StorageService.instance.removeItem(_tokenKey);
      }
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<dynamic> post(String endpoint,
      {dynamic data,
      Map<String, dynamic>? queryParams,
      Options? options}) async {
    try {
      final response = await _dio.post(endpoint,
          data: data, queryParameters: queryParams, options: options);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<dynamic> put(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<dynamic> delete(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.delete(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  InterceptorsWrapper _createInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Always check localStorage for the latest token (web only)
        if (kIsWeb && _authToken == null) {
          _loadStoredToken();
        }

        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (e, handler) => handler.next(e),
    );
  }
}
