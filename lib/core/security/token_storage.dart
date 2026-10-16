import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Armazenamento seguro de tokens e sessão (nunca em SharedPreferences).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _access = 'oc_access_token';
  static const _refresh = 'oc_refresh_token';
  static const _userJson = 'oc_user_json';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userJson,
  }) async {
    await Future.wait([
      _storage.write(key: _access, value: accessToken),
      _storage.write(key: _refresh, value: refreshToken),
      _storage.write(key: _userJson, value: userJson),
    ]);
  }

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _access, value: accessToken),
      _storage.write(key: _refresh, value: refreshToken),
    ]);
  }

  Future<String?> readAccessToken() => _storage.read(key: _access);
  Future<String?> readRefreshToken() => _storage.read(key: _refresh);
  Future<String?> readUserJson() => _storage.read(key: _userJson);

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _access),
      _storage.delete(key: _refresh),
      _storage.delete(key: _userJson),
    ]);
  }
}
