import 'package:dio/dio.dart';
import 'package:resellio/core/network/api_exception.dart';

class ApiClient {
  final Dio _dio;
  String? _authToken;

  ApiClient(String baseUrl) : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.interceptors.add(_createInterceptor());
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<dynamic> post(String endpoint, {dynamic data, Options? options}) async {
    try {
      final response = await _dio.post(endpoint, data: data, options: options);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  
  InterceptorsWrapper _createInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (e, handler) => handler.next(e),
    );
  }
}
