import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:resellio/core/models/cart_model.dart';
import 'package:resellio/core/models/ticket_model.dart';
import 'package:resellio/core/repositories/cart_repository.dart';
import 'package:resellio/core/network/api_exception.dart';

class CartService extends ChangeNotifier {
  final CartRepository _cartRepository;
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  CartService(this._cartRepository) {
    fetchCartItems();
  }

  UnmodifiableListView<CartItem> get items => UnmodifiableListView(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(
        0.0,
        (sum, item) => sum + (item.quantity * item.price),
      );

  Future<void> _runAction(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      await fetchCartItems(); // Refresh cart after action
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'An unexpected error occurred.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCartItems() async {
    await _runAction(() async {
      _items = await _cartRepository.getCartItems();
    });
  }

  Future<void> addItem(TicketType ticketType) async {
    if (ticketType.typeId == null) throw Exception('Ticket type ID is required');
    await _runAction(
        () => _cartRepository.addToCart(ticketType.typeId!, 1));
  }

  Future<void> addResaleTicket(int ticketId) async {
    await _runAction(() => _cartRepository.addResaleTicketToCart(ticketId));
  }

  Future<void> removeItem(int cartItemId) async {
    await _runAction(() => _cartRepository.removeFromCart(cartItemId));
  }

  Future<void> clearCart() async {
    // This assumes a clear cart endpoint or iterates remove
    final currentItems = List<CartItem>.from(_items);
    await _runAction(() async {
      for (final item in currentItems) {
        await _cartRepository.removeFromCart(item.cartItemId);
      }
    });
  }

  Future<bool> checkout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final success = await _cartRepository.checkout();
      if (success) {
        _items.clear();
      }
      return success;
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } catch (e) {
      _error = 'An unexpected error occurred during checkout.';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
