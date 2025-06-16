import 'dart:html' as html;
import 'storage_service.dart';

class WebStorageService implements StorageService {
  @override
  String? getItem(String key) => html.window.localStorage[key];

  @override
  void setItem(String key, String value) => html.window.localStorage[key] = value;

  @override
  void removeItem(String key) => html.window.localStorage.remove(key);
}

StorageService getStorageService() => WebStorageService();
