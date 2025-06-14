import 'package:equatable/equatable.dart';

abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartCheckoutInProgress extends CartState {}

class CartCheckoutSuccess extends CartState {}

class CartCheckoutFailure extends CartState {
  final String error;
  const CartCheckoutFailure(this.error);
  @override
  List<Object?> get props => [error];
}
