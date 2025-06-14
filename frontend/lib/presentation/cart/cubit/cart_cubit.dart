import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/cart/cubit/cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final CartRepository _cartRepository;

  CartCubit(this._cartRepository) : super(CartInitial());

  Future<void> _handleAction(Future<void> Function() action) async {
    try {
      emit(CartLoading());
      await action();
      final items = await _cartRepository.getCartItems();
      emit(CartLoaded(items));
    } on ApiException catch (e) {
      emit(CartError(e.message));
    } catch (e) {
      emit(CartError("An unexpected error occurred: $e"));
    }
  }

  Future<void> fetchCart() async {
    await _handleAction(() async {});
  }

  Future<void> addItem(int ticketTypeId, int quantity) async {
    await _handleAction(() => _cartRepository.addToCart(ticketTypeId, quantity));
  }

  Future<void> removeItem(int cartItemId) async {
    await _handleAction(() => _cartRepository.removeFromCart(cartItemId));
  }

  Future<bool> checkout() async {
    if (state is! CartLoaded) return false;
    final loadedState = state as CartLoaded;
    if (loadedState.items.isEmpty) {
      emit(const CartError('Your cart is empty!'));
      return false;
    }

    try {
      emit(CartLoading());
      final success = await _cartRepository.checkout();
      if (success) {
        emit(const CartLoaded([]));
        return true;
      } else {
        emit(const CartError('Checkout failed. Please try again.'));
        return false;
      }
    } on ApiException catch (e) {
      emit(CartError(e.message));
      return false;
    } catch (e) {
      emit(CartError("An unexpected error occurred: $e"));
      return false;
    }
  }
}
