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
      cartItemId: json['cart_item_id'] ?? 0,
      ticketType: json['ticket_type'] != null
          ? TicketType.fromJson(json['ticket_type'])
          : null,
      quantity: json['quantity'] ?? 1,
      price: (json['ticket_type']?['price'] as num?)?.toDouble() ?? 0.0,
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

  Map<String, dynamic> toJson() {
    return {
      'cart_item_id': cartItemId,
      'ticket_type': ticketType?.toJson(),
      'quantity': quantity,
    };
  }
}