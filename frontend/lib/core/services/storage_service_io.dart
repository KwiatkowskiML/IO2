import 'storage_service.dart';

class IoStorageService implements StorageService {
  @override
  String? getItem(String key) => null;

  @override
  void setItem(String key, String value) {}

  @override
  void removeItem(String key) {}
}

StorageService getStorageService() => IoStorageService();
