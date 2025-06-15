import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/marketplace/cubit/marketplace_state.dart';

class MarketplaceCubit extends Cubit<MarketplaceState> {
  final ResaleRepository _resaleRepository;

  MarketplaceCubit(this._resaleRepository) : super(MarketplaceInitial());

  Future<void> loadListings({
    int page = 1,
    int limit = 20,
    String? search,
    int? eventId,
    String? venue,
    double? minPrice,
    double? maxPrice,
    double? minOriginalPrice,
    double? maxOriginalPrice,
    String? eventDateFrom,
    String? eventDateTo,
    bool? hasSeat,
    String sortBy = 'event_date',
    String sortOrder = 'asc',
    bool reset = false,
  }) async {
    try {
      if (reset || state is! MarketplaceLoaded) {
        emit(MarketplaceLoading());
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (eventId != null) {
        queryParams['event_id'] = eventId;
      }
      if (venue != null && venue.isNotEmpty) {
        queryParams['venue'] = venue;
      }
      if (minPrice != null) {
        queryParams['min_price'] = minPrice;
      }
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice;
      }
      if (minOriginalPrice != null) {
        queryParams['min_original_price'] = minOriginalPrice;
      }
      if (maxOriginalPrice != null) {
        queryParams['max_original_price'] = maxOriginalPrice;
      }
      if (eventDateFrom != null && eventDateFrom.isNotEmpty) {
        queryParams['event_date_from'] = eventDateFrom;
      }
      if (eventDateTo != null && eventDateTo.isNotEmpty) {
        queryParams['event_date_to'] = eventDateTo;
      }
      if (hasSeat != null) {
        queryParams['has_seat'] = hasSeat;
      }

      final listings = await _resaleRepository.getMarketplaceListingsWithParams(queryParams);

      if (reset || state is! MarketplaceLoaded) {
        emit(MarketplaceLoaded(listings));
      } else {
        final currentState = state as MarketplaceLoaded;
        emit(MarketplaceLoaded([...currentState.listings, ...listings]));
      }
    } on ApiException catch (e) {
      emit(MarketplaceError(e.message));
    } catch (e) {
      emit(MarketplaceError('An unexpected error occurred: $e'));
    }
  }

  Future<bool> loadMoreListings({
    required int page,
    int limit = 20,
    String? search,
    int? eventId,
    String? venue,
    double? minPrice,
    double? maxPrice,
    double? minOriginalPrice,
    double? maxOriginalPrice,
    String? eventDateFrom,
    String? eventDateTo,
    bool? hasSeat,
    String sortBy = 'event_date',
    String sortOrder = 'asc',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (eventId != null) {
        queryParams['event_id'] = eventId;
      }
      if (venue != null && venue.isNotEmpty) {
        queryParams['venue'] = venue;
      }
      if (minPrice != null) {
        queryParams['min_price'] = minPrice;
      }
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice;
      }
      if (minOriginalPrice != null) {
        queryParams['min_original_price'] = minOriginalPrice;
      }
      if (maxOriginalPrice != null) {
        queryParams['max_original_price'] = maxOriginalPrice;
      }
      if (eventDateFrom != null && eventDateFrom.isNotEmpty) {
        queryParams['event_date_from'] = eventDateFrom;
      }
      if (eventDateTo != null && eventDateTo.isNotEmpty) {
        queryParams['event_date_to'] = eventDateTo;
      }
      if (hasSeat != null) {
        queryParams['has_seat'] = hasSeat;
      }

      final newListings = await _resaleRepository.getMarketplaceListingsWithParams(queryParams);

      if (state is MarketplaceLoaded) {
        final currentState = state as MarketplaceLoaded;
        emit(MarketplaceLoaded([...currentState.listings, ...newListings]));
        return newListings.length == limit; // Return true if there might be more data
      }

      return false;
    } catch (e) {
      // Don't emit error state for pagination failures, just return false
      return false;
    }
  }

  Future<void> purchaseTicket(int ticketId) async {
    if (state is! MarketplaceLoaded) return;
    final loadedState = state as MarketplaceLoaded;

    emit(MarketplacePurchaseInProgress(loadedState.listings, ticketId));

    try {
      await _resaleRepository.purchaseResaleTicket(ticketId);
      // Remove the purchased ticket from the list
      final updatedListings = loadedState.listings
          .where((listing) => listing.ticketId != ticketId)
          .toList();
      emit(MarketplaceLoaded(updatedListings));
    } on ApiException {
      emit(MarketplaceLoaded(loadedState.listings));
      rethrow;
    } catch (e) {
      emit(MarketplaceLoaded(loadedState.listings));
      throw Exception('An unexpected error occurred during purchase.');
    }
  }
}