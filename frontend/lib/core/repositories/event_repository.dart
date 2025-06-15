import 'package:resellio/core/models/models.dart';
import 'package:resellio/core/network/api_client.dart';

abstract class EventRepository {
  Future<List<Event>> getEvents();
  Future<List<Event>> getOrganizerEvents(int organizerId);
  Future<List<TicketType>> getTicketTypesForEvent(int eventId);
  Future<Event> createEvent(EventCreate eventData);
  Future<Event> updateEvent(int eventId, EventCreate eventData);
  Future<bool> cancelEvent(int eventId);
  Future<void> notifyParticipants(int eventId, String message);
  Future<TicketType> createTicketType(Map<String, dynamic> data);
  Future<bool> deleteTicketType(int typeId);
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
  Future<List<Event>> getOrganizerEvents(int organizerId) async {
    final data =
        await _apiClient.get('/events', queryParams: {'organizer_id': organizerId});
    return (data as List).map((e) => Event.fromJson(e)).toList();
  }

  @override
  Future<List<TicketType>> getTicketTypesForEvent(int eventId) async {
    final data = await _apiClient
        .get('/ticket-types/', queryParams: {'event_id': eventId});
    return (data as List).map((t) => TicketType.fromJson(t)).toList();
  }

  @override
  Future<Event> createEvent(EventCreate eventData) async {
    final data = await _apiClient.post('/events/', data: eventData.toJson());
    return Event.fromJson(data);
  }

  @override
  Future<Event> updateEvent(int eventId, EventCreate eventData) async {
    final data = await _apiClient.put('/events/$eventId', data: eventData.toJson());
    return Event.fromJson(data);
  }

  @override
  Future<bool> cancelEvent(int eventId) async {
    final response = await _apiClient.delete('/events/$eventId');
    return response as bool;
  }

  @override
  Future<void> notifyParticipants(int eventId, String message) async {
    await _apiClient.post('/events/$eventId/notify', data: {'message': message});
  }

  @override
  Future<TicketType> createTicketType(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/ticket-types/', data: data);
    return TicketType.fromJson(response);
  }

  @override
  Future<bool> deleteTicketType(int typeId) async {
    final response = await _apiClient.delete('/ticket-types/$typeId');
    return response as bool;
  }
}
