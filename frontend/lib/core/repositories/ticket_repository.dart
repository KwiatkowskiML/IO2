import 'package:resellio/core/models/ticket_model.dart';
import 'package:resellio/core/network/api_client.dart';

abstract class TicketRepository {
  Future<List<TicketDetailsModel>> getMyTickets();
  Future<void> listTicketForResale(int ticketId, double price);
  Future<void> cancelResaleListing(int ticketId);
}

class ApiTicketRepository implements TicketRepository {
  final ApiClient _apiClient;
  ApiTicketRepository(this._apiClient);

  @override
  Future<List<TicketDetailsModel>> getMyTickets() async {
    final data = await _apiClient.get('/tickets/');
    return (data as List).map((e) => TicketDetailsModel.fromJson(e)).toList();
  }

  @override
  Future<void> listTicketForResale(int ticketId, double price) async {
    await _apiClient.post('/tickets/$ticketId/resell', data: {'price': price});
  }

  @override
  Future<void> cancelResaleListing(int ticketId) async {
    await _apiClient.delete('/tickets/$ticketId/resell');
  }
}
