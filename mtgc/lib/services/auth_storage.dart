import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the JWT access token in the platform's secure storage
/// (Keychain on iOS, Keystore/EncryptedSharedPreferences on Android,
/// libsecret on Linux, etc.).
class AuthStorage {
  static const String _key = 'jwt_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) =>
      _storage.write(key: _key, value: token);

  static Future<String?> readToken() => _storage.read(key: _key);

  static Future<void> clear() => _storage.delete(key: _key);
}
