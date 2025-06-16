import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/cart/cubit/cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final CartRepository _cartRepository;

  CartCubit(this._cartRepository) : super(CartInitial());

  Future<void> _handleAction(Future<void> Function() action) async {
    try {
      final currentState = state;
      if (currentState is CartLoaded) {
        emit(CartLoading(currentState.items));
      } else {
        emit(const CartLoading([]));
      }

      await action();
      await fetchCart();
    } on ApiException catch (e) {
      emit(CartError(e.message));
      rethrow;
    } catch (e) {
      emit(CartError("An unexpected error occurred: $e"));
      await fetchCart();
    }
  }

  Future<void> fetchCart() async {
    try {
      emit(CartLoading(state is CartLoaded ? (state as CartLoaded).items : []));
      final items = await _cartRepository.getCartItems();
      emit(CartLoaded(items));
    } on ApiException catch (e) {
      emit(CartError(e.message));
    } catch (e) {
      emit(CartError("An unexpected error occurred: $e"));
    }
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
      emit(CartLoading(loadedState.items));
      final success = await _cartRepository.checkout();
      if (success) {
        emit(const CartLoaded([]));
        return true;
      } else {
        emit(const CartError('Checkout failed. Please try again.'));
        await fetchCart();
        return false;
      }
    } on ApiException catch (e) {
      emit(CartError(e.message));
      await fetchCart();
      return false;
    } catch (e) {
      emit(CartError("An unexpected error occurred: $e"));
      await fetchCart();
      return false;
    }
  }
}
