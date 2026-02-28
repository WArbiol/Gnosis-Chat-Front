import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  static Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  static Future<String?> getToken() => _storage.read(key: _keyToken);

  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _keyRefreshToken, value: token);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _keyRefreshToken);

  static Future<void> clearAll() => _storage.deleteAll();
}
