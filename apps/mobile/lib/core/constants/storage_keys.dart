/// Keys used for secure key/value persistence. Centralized to avoid typos and
/// accidental collisions across features.
class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'auth.accessToken';
  static const String refreshToken = 'auth.refreshToken';
  static const String userId = 'auth.userId';

  /// Cached FCM token; re-registered with the backend on change.
  static const String fcmToken = 'device.fcmToken';
}
