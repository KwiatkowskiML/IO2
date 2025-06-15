import 'package:resellio/core/models/resale_ticket_listing.dart';
import 'package:resellio/core/models/ticket_model.dart';
import 'package:resellio/core/network/api_client.dart';

abstract class ResaleRepository {
  Future<List<ResaleTicketListing>> getMarketplaceListings(
      {int? eventId, double? minPrice, double? maxPrice});
  Future<TicketDetailsModel> purchaseResaleTicket(int ticketId);
  Future<List<ResaleTicketListing>> getMyResaleListings();
}

class ApiResaleRepository implements ResaleRepository {
  final ApiClient _apiClient;
  ApiResaleRepository(this._apiClient);

  @override
  Future<List<ResaleTicketListing>> getMarketplaceListings(
      {int? eventId, double? minPrice, double? maxPrice}) async {
    final queryParams = <String, dynamic>{
      if (eventId != null) 'event_id': eventId,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
    };
    final data =
        await _apiClient.get('/resale/marketplace', queryParams: queryParams);
    return (data as List).map((e) => ResaleTicketListing.fromJson(e)).toList();
  }

  @override
  Future<TicketDetailsModel> purchaseResaleTicket(int ticketId) async {
    final data =
        await _apiClient.post('/resale/purchase', data: {'ticket_id': ticketId});
    return TicketDetailsModel.fromJson(data);
  }

  @override
  Future<List<ResaleTicketListing>> getMyResaleListings() async {
    final data = await _apiClient.get('/resale/my-listings');
    return (data as List).map((e) => ResaleTicketListing.fromJson(e)).toList();
  }
}
