import 'package:resellio/core/models/ticket_model.dart';

class CartItem {
  final int cartItemId;
  final TicketType? ticketType;
  final int quantity;
  final double price; 

  CartItem({
    required this.cartItemId,
    this.ticketType,
    required this.quantity,
    required this.price,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cart_item_id'],
      // The backend sends a ticket_type object if it's a standard purchase
      ticketType: json['ticket_type'] != null
          ? TicketType.fromJson(json['ticket_type'])
          : null,
      quantity: json['quantity'],
      // Fallback logic for price if ticket_type is null (e.g., resale)
      price: json['ticket_type']?['price'] ?? 0.0,
    );
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      cartItemId: cartItemId,
      ticketType: ticketType,
      quantity: quantity ?? this.quantity,
      price: price,
    );
  }
}
