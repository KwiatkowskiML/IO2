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
    useMockData: false, // Set to true to use mock data even with local backend
  );

  static final ApiConfig productionConfig = ApiConfig(
    environment: Environment.production,
    // Replace with your actual AWS API Gateway URL
    baseUrl: 'https://your-api.aws.com/api',
    useMockData: false, // Set to true to use mock data even with production backend
  );
}

// --- API Service ---

class ApiService {
  // --- Configuration ---
  // CHANGE THIS TO SWITCH BETWEEN ENVIRONMENTS
  // Use mockConfig for development with mock data
  // Use localConfig for development with local backend
  // Use productionConfig for production
  // static final ApiConfig _currentConfig = ApiConfig.mockConfig;
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

  // Helper method to determine if we should use mock data
  bool get _shouldUseMockData => _currentConfig.useMockData || _currentConfig.environment == Environment.mock;

  String _handleDioError(DioException e) {
    debugPrint('API Error Details: ${e.type} - ${e.message}');
    debugPrint('Response: ${e.response?.data}');
    debugPrint('Status Code: ${e.response?.statusCode}');
    
    // Handle connection errors specifically
    if (e.type == DioExceptionType.connectionError || 
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection error: Unable to connect to the server. Please check if the backend is running.';
    }
    
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
    if (_shouldUseMockData) {
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
    // Event 1 tickets
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
    // Event 2 tickets
    TicketType.fromJson({
      'type_id': 3,
      'event_id': 2,
      'description': 'Standard Ticket',
      'max_count': 200,
      'price': 39.99,
      'currency': 'USD',
    }),
    TicketType.fromJson({
      'type_id': 4,
      'event_id': 2,
      'description': 'Premium Seating',
      'max_count': 50,
      'price': 89.99,
      'currency': 'USD',
    }),
    // Event 3 tickets
    TicketType.fromJson({
      'type_id': 5,
      'event_id': 3,
      'description': 'Early Bird',
      'max_count': 150,
      'price': 29.99,
      'currency': 'USD',
    }),
    TicketType.fromJson({
      'type_id': 6,
      'event_id': 3,
      'description': 'VIP Experience',
      'max_count': 25,
      'price': 199.99,
      'currency': 'USD',
    }),
    // Event 4 tickets
    TicketType.fromJson({
      'type_id': 7,
      'event_id': 4,
      'description': 'General Admission',
      'max_count': 300,
      'price': 59.99,
      'currency': 'USD',
    }),
    TicketType.fromJson({
      'type_id': 8,
      'event_id': 4,
      'description': 'Front Row',
      'max_count': 30,
      'price': 149.99,
      'currency': 'USD',
    }),
    // Event 5 tickets
    TicketType.fromJson({
      'type_id': 9,
      'event_id': 5,
      'description': 'Student Discount',
      'max_count': 100,
      'price': 19.99,
      'currency': 'USD',
    }),
    TicketType.fromJson({
      'type_id': 10,
      'event_id': 5,
      'description': 'Regular Price',
      'max_count': 250,
      'price': 44.99,
      'currency': 'USD',
    }),
    // Add tickets for remaining events (6-10)
    TicketType.fromJson({
      'type_id': 11,
      'event_id': 6,
      'description': 'General Admission',
      'max_count': 180,
      'price': 35.99,
      'currency': 'USD',
    }),
    TicketType.fromJson({
      'type_id': 12,
      'event_id': 7,
      'description': 'Standard Ticket',
      'max_count': 220,
      'price': 52.99,
      'currency': 'USD',
    }),
    TicketType.fromJson({
      'type_id': 13,
      'event_id': 8,
      'description': 'General Admission',
      'max_count': 160,
      'price': 41.99,
      'currency': 'USD',
    }),
    TicketType.fromJson({
      'type_id': 14,
      'event_id': 9,
      'description': 'Standard Ticket',
      'max_count': 190,
      'price': 48.99,
      'currency': 'USD',
    }),
    TicketType.fromJson({
      'type_id': 15,
      'event_id': 10,
      'description': 'General Admission',
      'max_count': 210,
      'price': 55.99,
      'currency': 'USD',
    }),
  ];

  final List<TicketDetailsModel> _mockTickets = [
    TicketDetailsModel.fromJson({
      'ticket_id': 1,
      'type_id': 1,
      'owner_id': 1,
      'seat': 'GA-123',
      'original_price': 49.99,
      // Mocked relation data
      'event_name': 'Epic Music Festival 1',
      'event_start_date':
          DateTime.now().add(const Duration(days: 5)).toIso8601String(),
    }),
    TicketDetailsModel.fromJson({
      'ticket_id': 2,
      'type_id': 2,
      'owner_id': 1,
      'seat': 'VIP-A1',
      'resell_price': 150.0,
      'original_price': 129.99,
      // Mocked relation data
      'event_name': 'Another Cool Concert',
      'event_start_date':
          DateTime.now().add(const Duration(days: 10)).toIso8601String(),
    }),
  ];

  // --- API Methods ---

  Future<List<Event>> getEvents() async {
    if (_shouldUseMockData) {
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
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockTicketTypes.where((t) => t.eventId == eventId).toList();
    }
    try {
      final response = await _dio.get('/ticket-types/', queryParameters: {
        'event_id': eventId,
      });
      return (response.data as List)
          .map((e) => TicketType.fromJson(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TicketDetailsModel>> getMyTickets([int? userId]) async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return _mockTickets.where((t) => t.ownerId == (userId ?? 1)).toList();
    }
    try {
      // The backend will automatically filter by the authenticated user's tickets
      // If userId is provided, we can optionally include it as a query parameter
      String endpoint = '/tickets';
      if (userId != null) {
        endpoint = '/tickets?owner_id=$userId';
      }
      
      final response = await _dio.get(endpoint);
      return (response.data as List)
          .map((e) => TicketDetailsModel.fromJson(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // --- Marketplace/Resale Methods ---

  Future<List<dynamic>> getMarketplaceListings({
    int? eventId,
    double? minPrice,
    double? maxPrice,
  }) async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      // Return mock marketplace listings
      return [
        {
          'ticket_id': 1,
          'original_price': 99.99,
          'resell_price': 85.00,
          'event_name': 'Rock Concert 2024',
          'event_date': DateTime.now().add(const Duration(days: 15)).toIso8601String(),
          'venue_name': 'Madison Square Garden',
          'ticket_type_description': 'VIP Access',
          'seat': 'A12',
        },
        {
          'ticket_id': 2,
          'original_price': 49.99,
          'resell_price': 60.00,
          'event_name': 'Jazz Night',
          'event_date': DateTime.now().add(const Duration(days: 8)).toIso8601String(),
          'venue_name': 'Blue Note',
          'ticket_type_description': 'General Admission',
          'seat': null,
        },
        {
          'ticket_id': 3,
          'original_price': 129.99,
          'resell_price': 110.00,
          'event_name': 'Comedy Show',
          'event_date': DateTime.now().add(const Duration(days: 22)).toIso8601String(),
          'venue_name': 'Comedy Central',
          'ticket_type_description': 'Premium Seating',
          'seat': 'B5',
        },
      ].map((listing) => {
        'ticket_id': listing['ticket_id'],
        'original_price': listing['original_price'],
        'resell_price': listing['resell_price'],
        'event_name': listing['event_name'],
        'event_date': listing['event_date'],
        'venue_name': listing['venue_name'],
        'ticket_type_description': listing['ticket_type_description'],
        'seat': listing['seat'],
      }).toList();
    }

    try {
      final queryParams = <String, String>{};
      if (eventId != null) queryParams['event_id'] = eventId.toString();
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();

      final response = await _dio.get(
        '/resale/marketplace',
        queryParameters: queryParams,
      );
      return response.data as List;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> purchaseResaleTicket(int ticketId) async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return; // Simulate successful purchase
    }

    try {
      await _dio.post('/resale/purchase', data: {
        'ticket_id': ticketId,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getMyResaleListings() async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return [
        {
          'ticket_id': 4,
          'original_price': 75.00,
          'resell_price': 80.00,
          'event_name': 'My Listed Event',
          'event_date': DateTime.now().add(const Duration(days: 12)).toIso8601String(),
          'venue_name': 'Local Arena',
          'ticket_type_description': 'Standard',
          'seat': 'C10',
        }
      ];
    }

    try {
      final response = await _dio.get('/resale/my-listings');
      return response.data as List;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> listTicketForResale(int ticketId, double resellPrice) async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    try {
      await _dio.post('/tickets/$ticketId/resell', data: {
        'price': resellPrice,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelResaleListing(int ticketId) async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    try {
      await _dio.delete('/tickets/$ticketId/resell');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  // --- User Profile Methods ---

  Future<Map<String, dynamic>> getUserProfile() async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return {
        'user_id': 1,
        'email': 'test@example.com',
        'login': 'testuser',
        'first_name': 'Test',
        'last_name': 'User',
        'user_type': 'customer',
        'is_active': true,
      };
    }

    try {
      final response = await _dio.get('/user/me');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    try {
      await _dio.put('/user/update-profile', data: profileData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  // --- Organizer Methods ---

  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData) async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return {
        'event_id': 999,
        'name': eventData['name'],
        'description': eventData['description'],
        'start_date': eventData['start_date'],
        'end_date': eventData['end_date'],
        'location_name': eventData['location_name'],
        'status': 'pending',
        'organizer_id': 1,
      };
    }

    try {
      final response = await _dio.post('/events/', data: eventData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getOrganizerEvents(int organizerId) async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return [
        {
          'event_id': 1,
          'name': 'My Event 1',
          'description': 'My first event',
          'start_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'end_date': DateTime.now().add(const Duration(days: 30, hours: 4)).toIso8601String(),
          'location_name': 'My Venue',
          'status': 'active',
          'total_tickets': 200,
          'organizer_id': organizerId,
        },
        {
          'event_id': 2,
          'name': 'My Event 2',
          'description': 'My second event',
          'start_date': DateTime.now().add(const Duration(days: 45)).toIso8601String(),
          'end_date': DateTime.now().add(const Duration(days: 45, hours: 6)).toIso8601String(),
          'location_name': 'Another Venue',
          'status': 'pending',
          'total_tickets': 150,
          'organizer_id': organizerId,
        },
      ];
    }

    try {
      final response = await _dio.get('/events?organizer_id=$organizerId');
      return response.data as List;
    } catch (e) {
      rethrow;
    }
  }

  // --- Admin Methods ---

  Future<List<dynamic>> getPendingOrganizers() async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return [
        {
          'user_id': 10,
          'email': 'organizer1@example.com',
          'first_name': 'John',
          'last_name': 'Organizer',
          'company_name': 'Event Company 1',
          'is_verified': false,
          'organizer_id': 5,
        },
        {
          'user_id': 11,
          'email': 'organizer2@example.com',
          'first_name': 'Jane',
          'last_name': 'Events',
          'company_name': 'Party Planners Inc',
          'is_verified': false,
          'organizer_id': 6,
        },
      ];
    }

    try {
      final response = await _dio.get('/auth/pending-organizers');
      return response.data as List;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyOrganizer(int organizerId) async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    try {
      await _dio.post('/auth/verify-organizer', data: {
        'organizer_id': organizerId,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getAllUsers() async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return [
        {
          'user_id': 1,
          'email': 'customer1@example.com',
          'first_name': 'Alice',
          'last_name': 'Customer',
          'user_type': 'customer',
          'is_active': true,
        },
        {
          'user_id': 2,
          'email': 'organizer1@example.com',
          'first_name': 'Bob',
          'last_name': 'Organizer',
          'user_type': 'organizer',
          'is_active': true,
        },
        {
          'user_id': 3,
          'email': 'banned@example.com',
          'first_name': 'Charlie',
          'last_name': 'Banned',
          'user_type': 'customer',
          'is_active': false,
        },
      ];
    }

    try {
      final response = await _dio.get('/admin/users'); // This endpoint might need to be created
      return response.data as List;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> banUser(int userId) async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    try {
      await _dio.post('/auth/ban-user/$userId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unbanUser(int userId) async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    try {
      await _dio.post('/auth/unban-user/$userId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  // Test connection to the backend
  Future<bool> testConnection() async {
    if (_shouldUseMockData) {
      return true; // Mock data always "works"
    }
    
    try {
      final response = await _dio.get('/health', options: Options(
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  // --- Cart Methods ---

  Future<List<dynamic>> getCartItems() async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return []; // Mock empty cart
    }

    try {
      final response = await _dio.get('/cart/items');
      return response.data as List;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addToCart(int ticketTypeId, int quantity) async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    try {
      await _dio.post('/cart/items', queryParameters: {
        'ticket_type_id': ticketTypeId,
        'quantity': quantity,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFromCart(int cartItemId) async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    try {
      await _dio.delete('/cart/items/$cartItemId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> checkout() async {
    if (_shouldUseMockData) {
      await Future.delayed(const Duration(seconds: 2));
      return true; // Mock successful checkout
    }

    try {
      final response = await _dio.post('/cart/checkout');
      return response.data == true;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  // --- Ticket Methods ---
}
