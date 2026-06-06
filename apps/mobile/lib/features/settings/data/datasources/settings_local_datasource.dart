import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/notification_preferences.dart';

/// Persists device-side settings (notification preferences) as a JSON blob in
/// secure storage. There is no server endpoint for these in the API contract,
/// so they live only on-device.
abstract class SettingsLocalDataSource {
  Future<NotificationPreferences> readNotificationPreferences();
  Future<void> writeNotificationPreferences(NotificationPreferences prefs);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsLocalDataSourceImpl(this._storage);

  final FlutterSecureStorage _storage;

  /// Storage key for the serialized [NotificationPreferences].
  static const String _prefsKey = 'settings.notificationPreferences';

  @override
  Future<NotificationPreferences> readNotificationPreferences() async {
    final raw = await _storage.read(key: _prefsKey);
    if (raw == null || raw.isEmpty) {
      return const NotificationPreferences(); // sensible defaults
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationPreferences.fromJson(map);
    } catch (_) {
      // Corrupt blob -> fall back to defaults rather than crash.
      return const NotificationPreferences();
    }
  }

  @override
  Future<void> writeNotificationPreferences(
    NotificationPreferences prefs,
  ) async {
    await _storage.write(key: _prefsKey, value: jsonEncode(prefs.toJson()));
  }
}
