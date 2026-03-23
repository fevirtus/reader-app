import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  SecureStore() : _storage = const FlutterSecureStorage();

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';

  final FlutterSecureStorage _storage;

  Future<void> setAccessToken(String token) =>
      _storage.write(key: _kAccessToken, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);

  Future<void> setRefreshToken(String token) =>
      _storage.write(key: _kRefreshToken, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<void> clear() => _storage.deleteAll();
}
