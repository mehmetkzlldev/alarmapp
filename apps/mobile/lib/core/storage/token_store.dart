import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import 'package:alarmy/core/constants/storage_keys.dart';

/// Immutable token pair returned by the auth endpoints.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// Persists JWTs in the platform secure enclave (Keychain / Keystore).
///
/// Tokens NEVER touch SharedPreferences/plaintext. The refresh token is the
/// long-lived credential (~30d, rotating); on every successful refresh the new
/// pair overwrites the old via [save], which keeps the rotation chain intact.
abstract class TokenStore {
  Future<void> save(AuthTokens tokens);
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<AuthTokens?> readTokens();
  Future<void> clear();

  /// Cheap auth check used by the router redirect (presence of a refresh token).
  Future<bool> hasSession();
}

@LazySingleton(as: TokenStore)
class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> save(AuthTokens tokens) async {
    await Future.wait([
      _storage.write(key: StorageKeys.accessToken, value: tokens.accessToken),
      _storage.write(key: StorageKeys.refreshToken, value: tokens.refreshToken),
    ]);
  }

  @override
  Future<String?> readAccessToken() =>
      _storage.read(key: StorageKeys.accessToken);

  @override
  Future<String?> readRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken);

  @override
  Future<AuthTokens?> readTokens() async {
    final access = await readAccessToken();
    final refresh = await readRefreshToken();
    if (access == null || refresh == null) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
      _storage.delete(key: StorageKeys.userId),
    ]);
  }

  @override
  Future<bool> hasSession() async {
    final refresh = await readRefreshToken();
    return refresh != null && refresh.isNotEmpty;
  }
}
