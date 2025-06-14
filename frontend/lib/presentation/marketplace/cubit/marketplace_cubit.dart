import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/resale_repository.dart';
import 'package:resellio/presentation/marketplace/cubit/marketplace_state.dart';

class MarketplaceCubit extends Cubit<MarketplaceState> {
  final ResaleRepository _resaleRepository;

  MarketplaceCubit(this._resaleRepository) : super(MarketplaceInitial());

  Future<void> loadListings(
      {int? eventId, double? minPrice, double? maxPrice}) async {
    try {
      emit(MarketplaceLoading());
      final listings = await _resaleRepository.getMarketplaceListings(
        eventId: eventId,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      emit(MarketplaceLoaded(listings));
    } on ApiException catch (e) {
      emit(MarketplaceError(e.message));
    } catch (e) {
      emit(MarketplaceError('An unexpected error occurred: $e'));
    }
  }

  Future<void> purchaseTicket(int ticketId) async {
    if (state is! MarketplaceLoaded) return;
    final loadedState = state as MarketplaceLoaded;

    emit(MarketplacePurchaseInProgress(loadedState.listings, ticketId));

    try {
      await _resaleRepository.purchaseResaleTicket(ticketId);
      // On success, refresh the whole list
      await loadListings();
    } on ApiException {
      // Revert to loaded state on error to un-disable button
      emit(MarketplaceLoaded(loadedState.listings));
      // Then throw to be caught by BlocListener for SnackBar
      rethrow;
    } catch (e) {
      emit(MarketplaceLoaded(loadedState.listings));
      throw Exception('An unexpected error occurred during purchase.');
    }
  }
}
