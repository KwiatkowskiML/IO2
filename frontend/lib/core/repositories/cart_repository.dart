import 'package:resellio/core/network/api_client.dart';

abstract class CartRepository {
  // TODO: Add methods for checkout, add, remove
}

class ApiCartRepository implements CartRepository {
  final ApiClient _apiClient;
  ApiCartRepository(this._apiClient);
  // TODO: Implementation 
}
