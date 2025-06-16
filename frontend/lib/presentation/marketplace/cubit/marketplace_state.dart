import 'package:equatable/equatable.dart';
import 'package:resellio/core/models/resale_ticket_listing.dart';

abstract class MarketplaceState extends Equatable {
  const MarketplaceState();
  @override
  List<Object?> get props => [];
}

class MarketplaceInitial extends MarketplaceState {}

class MarketplaceLoading extends MarketplaceState {}

class MarketplaceLoaded extends MarketplaceState {
  final List<ResaleTicketListing> listings;
  const MarketplaceLoaded(this.listings);
  @override
  List<Object> get props => [listings];
}

class MarketplaceError extends MarketplaceState {
  final String message;
  const MarketplaceError(this.message);
  @override
  List<Object> get props => [message];
}

class MarketplacePurchaseInProgress extends MarketplaceLoaded {
  final int processingTicketId;
  const MarketplacePurchaseInProgress(
      super.listings, this.processingTicketId);
  @override
  List<Object> get props => [listings, processingTicketId];
}
