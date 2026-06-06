import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

/// Requests the OS permissions an alarm needs to actually FIRE and RING:
///   - [Permission.notification] (Android 13+) so the full-screen ring intent
///     can post its high-priority notification, and
///   - [Permission.scheduleExactAlarm] (Android 12+) so AlarmManager.setAlarmClock
///     is allowed to wake the device at the exact time.
///
/// No-ops on the web. Safe to call repeatedly — it only prompts while a
/// permission is still denied, and never throws (permissions are best-effort and
/// must never block alarm creation).
Future<void> ensureAlarmPermissions() async {
  if (kIsWeb) return;
  try {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  } catch (_) {
    // Plugin/platform without these permissions — ignore.
  }
}
