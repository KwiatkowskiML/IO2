import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:resellio/core/models/cart_model.dart';
import 'package:resellio/core/models/ticket_model.dart';
import 'package:resellio/core/repositories/cart_repository.dart';

class CartService extends ChangeNotifier {
  final CartRepository _cartRepository;
  final List<CartItem> _items = [];

  CartService(this._cartRepository);

  UnmodifiableListView<CartItem> get items => UnmodifiableListView(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(
    0.0,
    (sum, item) => sum + (item.quantity * item.ticketType.price),
  );

  Future<void> addItem(TicketType ticketType) async {
    try {
      if (ticketType.typeId == null) {
        throw Exception('Ticket type ID is required');
      }
      
      // TODO: In phase 2, call _cartRepository.addToCart here
      
      final index = _items.indexWhere(
        (item) => item.ticketType.typeId == ticketType.typeId,
      );

      if (index != -1) {
        _items[index] = _items[index].copyWith(
          quantity: _items[index].quantity + 1,
        );
      } else {
        _items.add(CartItem(ticketType: ticketType, quantity: 1));
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addResaleTicket(int ticketId, String eventName, String description, double price) async {
    try {
      // TODO: In phase 2, call _cartRepository.addResaleTicketToCart here
      
      final resaleTicketType = TicketType(
        typeId: ticketId,
        eventId: 0,
        description: '$eventName - $description (Resale)',
        price: price,
        maxCount: 1,
        currency: 'USD',
      );
      
      _items.add(CartItem(ticketType: resaleTicketType, quantity: 1));
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeItem(TicketType ticketType) async {
    try {
      // TODO: In phase 2, call _cartRepository.removeFromCart here
      final itemIndex = _items.indexWhere((item) => item.ticketType.typeId == ticketType.typeId);
      if (itemIndex != -1) {
        _items.removeAt(itemIndex);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
  }
  
  Future<bool> checkout() async {
    try {
      // TODO: In phase 2, call _cartRepository.checkout here
      final success = true; 
      
      if (success) {
        await clearCart();
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }
}
