import 'package:resellio/core/models/event_model.dart';
import 'package:resellio/core/models/ticket_model.dart';
import 'package:resellio/core/network/api_client.dart';

abstract class EventRepository {
  Future<List<Event>> getEvents();
  Future<List<TicketType>> getTicketTypesForEvent(int eventId);
}

class ApiEventRepository implements EventRepository {
  final ApiClient _apiClient;

  ApiEventRepository(this._apiClient);

  @override
  Future<List<Event>> getEvents() async {
    final data = await _apiClient.get('/events');
    return (data as List).map((e) => Event.fromJson(e)).toList();
  }

  @override
  Future<List<TicketType>> getTicketTypesForEvent(int eventId) async {
    final data =
        await _apiClient.get('/ticket-types/', queryParams: {'event_id': eventId});
    return (data as List).map((t) => TicketType.fromJson(t)).toList();
  }
}
