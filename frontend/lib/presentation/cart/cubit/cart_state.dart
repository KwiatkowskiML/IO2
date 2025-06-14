import 'package:equatable/equatable.dart';
import 'package:resellio/core/models/models.dart';

abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItem> items;
  const CartLoaded(this.items);

  double get totalPrice =>
      items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));

  @override
  List<Object?> get props => [items, totalPrice];
}

class CartError extends CartState {
  final String message;
  const CartError(this.message);
  @override
  List<Object> get props => [message];
}
