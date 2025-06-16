import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  factory ApiException.fromDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException('Connection Error: Please check your network and ensure the server is running.');
    }
    
    if (e.response?.data != null && e.response!.data is Map) {
      final detail = (e.response!.data as Map<String, dynamic>)['detail'];
      if (detail is String) {
        return ApiException(detail);
      }
    }
    
    return ApiException(e.response?.statusMessage ?? 'An unknown API error occurred');
  }

  @override
  String toString() => message;
}
