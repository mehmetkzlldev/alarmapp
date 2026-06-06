# Android Alarm Engine

This module makes alarms fire **reliably in the background, with the screen
locked**, play sound, and **require mission completion before they stop**.

## Architecture

```
AlarmSchedulerPlugin (MethodChannel 'app/alarm')
        │  schedule / cancel / snooze / stop
        ▼
AlarmManager.setAlarmClock(triggerAt, showIntent) + broadcast PendingIntent
        │  (exact, Doze-exempt, shows lock-screen alarm icon)
        ▼  at trigger time
AlarmReceiver (BroadcastReceiver)
        │  startForegroundService(...) + re-arm repeating alarm
        ▼
AlarmForegroundService
        ├── WakeLock (CPU stays awake, screen can be off)
        ├── MediaPlayer (USAGE_ALARM, looping) + Vibrator (repeating)
        ├── Notification with setFullScreenIntent(...) -> AlarmActivity
        └── AlarmSchedulerPlugin.emit("alarm_fired") -> EventChannel -> Dart
        ▼
AlarmActivity (showWhenLocked + turnScreenOn)
        └── hosts Flutter engine, routes to /alarm-ring -> AlarmRingScreen
                └── runs missions; on success Dart calls scheduler.stop(id)
                        -> service stops audio/vibration/wakelock

BootReceiver re-arms every persisted alarm after reboot / app update.
AlarmStore persists alarms (SharedPreferences JSON) for reboot rescheduling.
```

## Why `setAlarmClock`?

It is the only `AlarmManager` API that is **never deferred by Doze**, shows the
system alarm icon, and is treated by the OS as a genuine clock alarm. `setExact`
and `setExactAndAllowWhileIdle` are weaker and rate-limited. Using
`setAlarmClock` is what production alarm apps (incl. Alarmy) rely on.

## Permission flow by OS version

### Exact alarms

| OS | Permission | How it's obtained |
|----|-----------|-------------------|
| ≤ Android 11 | none | Exact alarms work without a permission. |
| Android 12 (API 31–32) | `SCHEDULE_EXACT_ALARM` | **User-grantable.** Pre-granted on install but the user can revoke it. Call `canScheduleExactAlarms()`; if false, send the user to `Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM` via `requestExactAlarmPermission()`. |
| Android 13+ (API 33+) | `USE_EXACT_ALARM` | **Auto-granted** for apps whose core purpose is an alarm clock. No prompt. This is why we declare both permissions — the system uses `USE_EXACT_ALARM` on 13+ and `SCHEDULE_EXACT_ALARM` on 12. |
| Android 14 (API 34) | `USE_EXACT_ALARM` | Same. Play Console requires a declaration that the app is an alarm/clock app to ship `USE_EXACT_ALARM`. |

**At app start** the Flutter layer should call
`AlarmScheduler.canScheduleExactAlarms()` and, if false (Android 12 only),
surface a one-tap prompt that calls `requestExactAlarmPermission()`.

### Notifications (Android 13+)

`POST_NOTIFICATIONS` is a runtime permission. The full-screen ring intent rides
on a notification, so request it on first launch (use `permission_handler`).
Without it the foreground-service notification is suppressed, though the
service + audio still run.

### Full-screen intent (Android 14+)

`USE_FULL_SCREEN_INTENT` is auto-granted for `CATEGORY_ALARM` apps. If a future
Play policy change makes it user-grantable, route the user to
`Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT`.

## Battery-optimization exemption (Doze / OEM killers)

`setAlarmClock` survives Doze, but the **foreground service that plays the
sound** can be killed early by aggressive OEM battery managers (Xiaomi, Oppo,
Vivo, Huawei, Samsung). To maximize reliability:

1. Call `AlarmScheduler.requestIgnoreBatteryOptimizations()` to show the system
   dialog (`Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`). This adds
   the app to the OS allow-list so the service is not throttled.
2. For OEMs with extra "auto-start"/"protected apps" screens (MIUI, ColorOS,
   FuntouchOS), deep-link or instruct the user to enable auto-start. There is no
   universal API; ship a short in-app guide keyed off `Build.MANUFACTURER`.
3. Keep the foreground service `START_STICKY` (already set) so the OS recreates
   it if killed under memory pressure.

> Do **not** request the battery exemption automatically with no context — Play
> policy requires a clear user-facing justification ("so your alarms ring
> reliably"). Gate it behind an explicit settings toggle / onboarding step.

## Reboot & update survival

Pending `AlarmManager` alarms are wiped on reboot. `BootReceiver` listens for
`BOOT_COMPLETED` / `LOCKED_BOOT_COMPLETED` / OEM quickboot / `MY_PACKAGE_REPLACED`
and re-arms every active alarm from `AlarmStore`. Ensure alarms are written to
`AlarmStore` whenever the Flutter app schedules them (the plugin does this in the
`schedule` handler).

## Custom sounds

Place looping alarm audio files in `android/app/src/main/res/raw/<name>.ogg|mp3`
and pass the bare `<name>` as the alarm `sound`. `"default"` uses the system
default alarm ringtone. See `AlarmForegroundService.resolveSoundUri`.

## Manual setup checklist

- [ ] Merge the permissions + components from `AndroidManifest.xml` into your
      app manifest.
- [ ] Set `minSdkVersion` ≥ 23 (WakeLock/Doze APIs) — 24+ recommended.
- [ ] Set `compileSdkVersion`/`targetSdkVersion` to 34 (Android 14) and add the
      `foregroundServiceType="mediaPlayback"` + matching permission.
- [ ] Register `AlarmSchedulerPlugin` in `MainActivity` /
      `configureFlutterEngine` (or auto-register if packaged as a plugin):
      `flutterEngine.plugins.add(AlarmSchedulerPlugin())`.
- [ ] (Optional) Pre-warm and cache a Flutter engine under id `"alarm_engine"`
      so `AlarmActivity` shows the ring UI instantly.
- [ ] Add raw sound resources if using custom alarm tones.
- [ ] Declare the app as an "Alarm & Reminders" app in the Play Console to ship
      `USE_EXACT_ALARM`.
