import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/network/api_client.dart';

abstract class CartRepository {
  Future<List<CartItem>> getCartItems();
  Future<void> addToCart(int ticketTypeId, int quantity);
  Future<void> addResaleTicketToCart(int ticketId);
  Future<void> removeFromCart(int cartItemId);
  Future<bool> checkout();
}

class ApiCartRepository implements CartRepository {
  final ApiClient _apiClient;
  ApiCartRepository(this._apiClient);

  @override
  Future<List<CartItem>> getCartItems() async {
    final data = await _apiClient.get('/cart/items');
    return (data as List).map((e) => CartItem.fromJson(e)).toList();
  }

  @override
  Future<void> addToCart(int ticketTypeId, int quantity) async {
    await _apiClient.post('/cart/items',
        queryParams: {'ticket_type_id': ticketTypeId, 'quantity': quantity});
  }

  @override
  Future<void> addResaleTicketToCart(int ticketId) async {
    await _apiClient.post('/cart/items', queryParams: {'ticket_id': ticketId});
  }

  @override
  Future<void> removeFromCart(int cartItemId) async {
    await _apiClient.delete('/cart/items/$cartItemId');
  }

  @override
  Future<bool> checkout() async {
    final response = await _apiClient.post('/cart/checkout');
    return response as bool;
  }
}
