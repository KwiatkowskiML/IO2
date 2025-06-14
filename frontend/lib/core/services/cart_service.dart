import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:resellio/core/models/cart_model.dart';
import 'package:resellio/core/models/ticket_model.dart';
import 'package:resellio/core/services/api_service.dart';

class CartService extends ChangeNotifier {
  final ApiService _apiService;
  final List<CartItem> _items = [];

  CartService(this._apiService);

  UnmodifiableListView<CartItem> get items => UnmodifiableListView(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(
    0.0,
    (sum, item) => sum + (item.quantity * item.ticketType.price),
  );

  Future<void> addItem(TicketType ticketType) async {
    try {
      // Check if typeId is not null
      if (ticketType.typeId == null) {
        throw Exception('Ticket type ID is required');
      }
      
      // Call the backend API to add item to cart
      await _apiService.addToCart(ticketType.typeId!, 1);
      
      // Update local state
      final index = _items.indexWhere(
        (item) => item.ticketType.typeId == ticketType.typeId,
      );

      if (index != -1) {
        // If it exists, increase the quantity
        _items[index] = _items[index].copyWith(
          quantity: _items[index].quantity + 1,
        );
      } else {
        // If not, add a new item
        _items.add(CartItem(ticketType: ticketType, quantity: 1));
      }
      notifyListeners();
    } catch (e) {
      // Handle errors - maybe show a snackbar in the UI
      rethrow;
    }
  }

  Future<void> removeItem(TicketType ticketType) async {
    try {
      // Find the cart item to get its ID for backend removal
      final itemIndex = _items.indexWhere((item) => item.ticketType.typeId == ticketType.typeId);
      if (itemIndex != -1) {
        // Note: This assumes we have a way to get cart item ID
        // In a real implementation, you might need to modify the cart model
        // to include cart item IDs from the backend
        
        // Remove from local state first
        _items.removeAt(itemIndex);
        notifyListeners();
      }
    } catch (e) {
      // Handle errors
      rethrow;
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
  }
  
  Future<bool> checkout() async {
    try {
      print('CartService: Starting checkout with ${_items.length} items');
      print('CartService: Total price: $totalPrice');
      
      // Log each item for debugging
      for (var item in _items) {
        print('CartService: Item - ${item.ticketType.description}, Qty: ${item.quantity}, Price: ${item.ticketType.price}');
      }
      
      final success = await _apiService.checkout();
      print('CartService: API checkout result: $success');
      
      if (success) {
        print('CartService: Clearing cart after successful checkout');
        // Clear the cart after successful checkout
        await clearCart();
      } else {
        print('CartService: Checkout failed, keeping cart items');
      }
      return success;
    } catch (e) {
      print('CartService: Checkout error: $e');
      print('CartService: Error type: ${e.runtimeType}');
      rethrow;
    }
  }
}
