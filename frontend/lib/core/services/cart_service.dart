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

  void addItem(TicketType ticketType) {
    // Check if the item already exists in the cart
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
    // In a real app, you would also call the backend API here to add the item
    // await _apiService.addToCart(ticketType.typeId, 1);
    notifyListeners();
  }

  void removeItem(TicketType ticketType) {
    _items.removeWhere((item) => item.ticketType.typeId == ticketType.typeId);
    // In a real app, you would call the backend to remove the item
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    // In a real app, you would call the backend to clear the cart
    notifyListeners();
  }
}
