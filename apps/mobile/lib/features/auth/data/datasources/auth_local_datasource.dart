import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/error/exceptions.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

/// Local persistence for auth credentials and the cached user profile.
///
/// Tokens are written to the platform secure enclave (Keychain on iOS,
/// EncryptedSharedPreferences on Android) — never to plain prefs. The cached
/// user is stored alongside so the app can render immediately at cold start.
abstract class AuthLocalDataSource {
  Future<void> cacheTokens(AuthTokensModel tokens);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();

  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();

  /// Clears every auth artefact (tokens + user). Used on logout and on an
  /// unrecoverable 401.
  Future<void> clear();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._storage);

  final FlutterSecureStorage _storage;

  /// Key for the cached user JSON blob (distinct from token keys).
  static const String _cachedUserKey = 'auth.cachedUser';

  @override
  Future<void> cacheTokens(AuthTokensModel tokens) async {
    try {
      // Write both keys; if either fails we surface a CacheException so the
      // repository can decide how to degrade.
      await _storage.write(
        key: StorageKeys.accessToken,
        value: tokens.accessToken,
      );
      await _storage.write(
        key: StorageKeys.refreshToken,
        value: tokens.refreshToken,
      );
    } catch (e) {
      throw CacheException('Failed to persist tokens: $e');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: StorageKeys.accessToken);
    } catch (e) {
      throw CacheException('Failed to read access token: $e');
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: StorageKeys.refreshToken);
    } catch (e) {
      throw CacheException('Failed to read refresh token: $e');
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await _storage.write(
        key: _cachedUserKey,
        value: jsonEncode(user.toJson()),
      );
      // Keep the lightweight userId key (used by other features) in sync.
      await _storage.write(key: StorageKeys.userId, value: user.id);
    } catch (e) {
      throw CacheException('Failed to cache user: $e');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final raw = await _storage.read(key: _cachedUserKey);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (e) {
      // A corrupt cache should not crash startup — treat as "no cached user".
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await Future.wait([
        _storage.delete(key: StorageKeys.accessToken),
        _storage.delete(key: StorageKeys.refreshToken),
        _storage.delete(key: StorageKeys.userId),
        _storage.delete(key: _cachedUserKey),
      ]);
    } catch (e) {
      throw CacheException('Failed to clear auth storage: $e');
    }
  }
}
