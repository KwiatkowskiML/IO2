import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:resellio/core/models/event_model.dart';
import 'package:resellio/core/models/ticket_model.dart';

// --- API Configuration ---

enum Environment { mock, local, production }

class ApiConfig {
  final Environment environment;
  final String baseUrl;
  final bool useMockData;

  ApiConfig({
    required this.environment,
    required this.baseUrl,
    this.useMockData = false,
  });

  static final ApiConfig mockConfig = ApiConfig(
    environment: Environment.mock,
    baseUrl: 'mock',
    useMockData: true,
  );

  static final ApiConfig localConfig = ApiConfig(
    environment: Environment.local,
    // Assumes API Gateway is running on localhost:8080 via Docker Compose
    baseUrl: 'http://localhost:8080/api',
  );

  static final ApiConfig productionConfig = ApiConfig(
    environment: Environment.production,
    // Replace with your actual AWS API Gateway URL
    baseUrl: 'https://your-api.aws.com/api',
  );
}

// --- API Service ---

class ApiService {
  // --- Configuration ---
  // CHANGE THIS TO SWITCH BETWEEN ENVIRONMENTS
  static final ApiConfig _currentConfig = ApiConfig.localConfig;

  final Dio _dio = Dio();
  String? _authToken;

  ApiService() {
    _dio.options.baseUrl = _currentConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // You can add global error handling here
          debugPrint('API Error: ${e.response?.statusCode} - ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  String _handleDioError(DioException e) {
    if (e.response?.data != null && e.response!.data is Map) {
      final data = e.response!.data as Map<String, dynamic>;
      final detail = data['detail'];

      if (detail is String) {
        return detail;
      }

      if (detail is List) {
        try {
          // Format FastAPI validation errors
          return detail
              .map((err) => err['msg'] as String? ?? 'Invalid input.')
              .join('\n');
        } catch (_) {
          // Fallback for unexpected list content
          return 'Invalid data provided.';
        }
      }
    }
    return e.response?.statusMessage ??
        e.message ??
        'An unknown error occurred';
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  // --- Auth Methods ---

  Future<String> login(String email, String password) async {
    if (_currentConfig.useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      // Return a mock JWT-like token for testing purposes
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0QGV4YW1wbGUuY29tIiwicm9sZSI6ImN1c3RvbWVyIiwidXNlcl9pZCI6MSwicm9sZV9pZCI6MSwibmFtZSI6IlRlc3QiLCJleHAiOjE3MDAwMDAwMDB9.mock_signature';
    }
    try {
      final response = await _dio.post(
        '/auth/token',
        data: {'username': email, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      if (response.data['token'] != null && response.data['token'].isNotEmpty) {
        return response.data['token'];
      } else {
        throw 'Login failed: ${response.data['message']}';
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> registerCustomer(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/register/customer', data: data);
      return response.data['token'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> registerOrganizer(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/register/organizer', data: data);
      return response.data['token'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  // --- Mock Data ---

  final List<Event> _mockEvents = List.generate(
    10,
    (index) => Event.fromJson({
      'event_id': index + 1,
      'organizer_id': 101,
      'name': 'Epic Music Festival ${index + 1}',
      'description':
          'An unforgettable music experience under the stars. Featuring top artists and amazing food.',
      'start_date':
          DateTime.now().add(Duration(days: index * 5)).toIso8601String(),
      'end_date':
          DateTime.now()
              .add(Duration(days: index * 5, hours: 6))
              .toIso8601String(),
      'minimum_age': 18,
      'location_name': 'Sunset Valley',
      'status': 'active',
      'categories': ['Music', 'Festival'],
      'total_tickets': 5000,
    }),
  );

  final List<TicketType> _mockTicketTypes = [
    TicketType.fromJson({
      'type_id': 1,
      'event_id': 1,
      'description': 'General Admission',
      'max_count': 100,
      'price': 49.99,
      'currency': 'USD',
    }),
    TicketType.fromJson({
      'type_id': 2,
      'event_id': 1,
      'description': 'VIP Access',
      'max_count': 20,
      'price': 129.99,
      'currency': 'USD',
    }),
  ];

  final List<TicketDetailsModel> _mockTickets = [
    TicketDetailsModel.fromJson({
      'ticket_id': 1,
      'type_id': 1,
      'owner_id': 1,
      'seat': 'GA-123',
      // Mocked relation data
      'eventName': 'Epic Music Festival 1',
      'eventStartDate':
          DateTime.now().add(const Duration(days: 5)).toIso8601String(),
    }),
    TicketDetailsModel.fromJson({
      'ticket_id': 2,
      'type_id': 2,
      'owner_id': 1,
      'seat': 'VIP-A1',
      'resell_price': 150.0,
      // Mocked relation data
      'eventName': 'Another Cool Concert',
      'eventStartDate':
          DateTime.now().add(const Duration(days: 10)).toIso8601String(),
    }),
  ];

  // --- API Methods ---

  Future<List<Event>> getEvents() async {
    if (_currentConfig.useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return _mockEvents;
    }
    try {
      final response = await _dio.get('/events');
      return (response.data as List).map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Failed to get events: $e');
      rethrow;
    }
  }

  Future<List<TicketType>> getTicketTypesForEvent(int eventId) async {
    if (_currentConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockTicketTypes.where((t) => t.eventId == eventId).toList();
    }
    try {
      final response = await _dio.get('/ticket-types?event_id=$eventId');
      return (response.data as List)
          .map((e) => TicketType.fromJson(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TicketDetailsModel>> getMyTickets(int userId) async {
    if (_currentConfig.useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return _mockTickets.where((t) => t.ownerId == userId).toList();
    }
    try {
      // Use the owner_id filter on the backend for security and efficiency
      final response = await _dio.get('/tickets?owner_id=$userId');
      return (response.data as List)
          .map((e) => TicketDetailsModel.fromJson(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
