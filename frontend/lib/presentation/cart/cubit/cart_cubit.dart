import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/services/cart_service.dart';
import 'package:resellio/presentation/cart/cubit/cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final CartService _cartService;

  CartCubit(this._cartService) : super(CartInitial());

  Future<void> checkout() async {
    if (_cartService.items.isEmpty) {
      emit(const CartCheckoutFailure('Your cart is empty!'));
      return;
    }
    emit(CartCheckoutInProgress());
    try {
      final success = await _cartService.checkout();
      if (success) {
        emit(CartCheckoutSuccess());
      } else {
        emit(const CartCheckoutFailure('Checkout failed. Please try again.'));
      }
    } catch (e) {
      emit(CartCheckoutFailure(e.toString()));
    }
  }
}
