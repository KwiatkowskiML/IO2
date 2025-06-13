import 'package:resellio/core/models/ticket_model.dart';

class CartItem {
  final TicketType ticketType;
  final int quantity;

  CartItem({required this.ticketType, required this.quantity});

  // This model is simple and primarily populated by the CartService,
  // so a fromJson might not be directly needed if the service handles it.

  // Create a copy with a new quantity
  CartItem copyWith({int? quantity}) {
    return CartItem(
      ticketType: ticketType,
      quantity: quantity ?? this.quantity,
    );
  }
}
