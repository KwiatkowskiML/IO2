import 'package:flutter/material.dart';
import 'package:resellio/core/models/event_model.dart';
import 'package:resellio/core/models/ticket_model.dart';
import 'package:resellio/core/services/api_service.dart';

class OrganizerService extends ChangeNotifier {
  final ApiService _apiService;

  OrganizerService(this._apiService);

  List<Event> _events = [];
  List<Event> get events => _events;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchEvents(int organizerId) async {
    _setLoading(true);
    try {
      _events = await _apiService.getOrganizerEvents(organizerId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createEvent(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.createEvent(data);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateEvent(int eventId, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.updateEvent(eventId, data);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelEvent(int eventId) async {
    _setLoading(true);
    try {
      await _apiService.cancelEvent(eventId);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> notifyParticipants(int eventId, String message) async {
    try {
      await _apiService.notifyParticipants(eventId, message);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<TicketType?> createTicketType(Map<String, dynamic> data) async {
    try {
      return await _apiService.createTicketType(data);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteTicketType(int typeId) async {
    try {
      return await _apiService.deleteTicketType(typeId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
