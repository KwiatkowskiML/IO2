import 'package:resellio/core/models/event_model.dart';
import 'package:resellio/core/network/api_client.dart';

abstract class EventRepository {
  Future<List<Event>> getEvents();
}

class ApiEventRepository implements EventRepository {
  final ApiClient _apiClient;

  ApiEventRepository(this._apiClient);

  @override
  Future<List<Event>> getEvents() async {
    final data = await _apiClient.get('/events');
    return (data as List).map((e) => Event.fromJson(e)).toList();
  }
}
