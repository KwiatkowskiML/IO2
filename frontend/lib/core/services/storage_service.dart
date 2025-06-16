import 'storage_service_stub.dart'
    if (dart.library.html) 'storage_service_web.dart'
    if (dart.library.io) 'storage_service_io.dart';

abstract class StorageService {
  static StorageService get instance => getStorageService();

  String? getItem(String key);
  void setItem(String key, String value);
  void removeItem(String key);
}
