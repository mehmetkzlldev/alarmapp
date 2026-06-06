# iOS Alarm Engine

This document explains how alarms work on iOS, the **hard platform limitations**,
and the entitlements/capabilities you must configure.

## TL;DR — iOS cannot do what Android does

Android can wake a **dead app** at an exact time (`AlarmManager`) and start a
foreground service that plays audio indefinitely. **iOS cannot.** There is no
public API to run arbitrary code at a scheduled time when your app is not
running. The OS owns alerting.

So on iOS we approximate a real alarm with two cooperating mechanisms:

1. **Local notifications** (`UNUserNotificationCenter`), one per occurrence,
   delivered by the OS at the scheduled time even if the app is killed.
2. **Critical Alerts** so the notification **sound plays through silent mode and
   Focus** and at a louder, system-controlled volume.
3. **Looping background audio** (`AVAudioPlayer` + `.playback` category +
   Background Audio capability) started the moment the app becomes active from
   the notification, so the alarm keeps sounding while the user completes the
   mission.

## Reliability caveats (be honest with users)

- If the app is **force-quit** by the user (swiped away in the app switcher),
  iOS will still deliver the **notification** (and its critical sound), but it
  will **not** start our looping `AVAudioPlayer` until the user taps the
  notification to launch the app. The single notification sound (up to ~30s)
  is all that plays automatically.
- iOS limits an app to **64 pending local notifications total**. We schedule a
  rolling window (`maxOccurrencesPerAlarm = 8` per alarm) and **top it up every
  time the app is opened**. Make sure the app reschedules on launch/foreground.
- Notification **sound files must be ≤ 30 seconds** and bundled in the app
  (`.caf` recommended). Longer looping is achieved by the in-app `AVAudioPlayer`,
  not the notification sound.
- Critical Alerts require an **Apple-approved entitlement** (see below). Without
  it, alarms will not bypass silent mode / Focus — they behave like normal
  time-sensitive notifications.
- There is no guaranteed exact-time background execution; treat iOS alarms as
  **best-effort** and communicate this in onboarding.

## Required capabilities & entitlements

### 1. Background Modes → Audio

In Xcode: **Signing & Capabilities → + Capability → Background Modes**, check
**Audio, AirPlay, and Picture in Picture**. This adds to `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### 2. Critical Alerts entitlement (Apple approval required)

Critical alerts need a special entitlement that Apple grants only after you
**request it via a form** (https://developer.apple.com/contact/request/notifications-critical-alerts-entitlement/).
Once approved, add to `Runner.entitlements`:

```xml
<key>com.apple.developer.usernotifications.critical-alerts</key>
<true/>
```

Then `requestAuthorization` (already calling `.criticalAlert`) will show the
"Allow Critical Alerts" prompt. The provisioning profile used for signing must
include this entitlement.

### 3. Notification usage strings

Add to `Info.plist` if not present:

```xml
<key>NSUserNotificationsUsageDescription</key>
<string>We use notifications to ring your alarms reliably.</string>
```

## Bundled sounds

- Add looping/alert tones to the Runner target (e.g. `alarm_default.caf`,
  plus any custom tones named to match the alarm `sound` value).
- The **notification** sound is the `.caf` referenced by
  `UNNotificationSound.criticalSoundNamed(...)`.
- The **in-app loop** is the same file played by `AVAudioPlayer` via
  `AlarmManager.soundURL`.

## Wiring summary

- `AppDelegate.swift` registers MethodChannel `app/alarm`, EventChannel
  `app/alarm/events`, and becomes the `UNUserNotificationCenterDelegate`.
- `AlarmManager.swift` schedules/cancels notifications and owns the looping
  `AVAudioPlayer`.
- On notification delivery/tap, `AppDelegate` calls `AlarmManager.startRinging`
  and emits `alarm_fired` to Dart, which navigates to `/alarm-ring`.
- When Dart reports all missions complete, it calls the `stop` method, which
  calls `AlarmManager.stopRinging`.

## Manual setup checklist

- [ ] Add **Background Modes → Audio** capability.
- [ ] Request and add the **Critical Alerts** entitlement; re-sign with a
      profile that includes it.
- [ ] Add `NSUserNotificationsUsageDescription` to `Info.plist`.
- [ ] Bundle `alarm_default.caf` (and any custom tones) in the Runner target.
- [ ] Reschedule alarms on app launch/foreground to refill the 64-notification
      window (call `AlarmManager.schedule` for every active alarm).
- [ ] In onboarding, clearly tell users iOS alarms are best-effort and ask them
      to keep the app installed and not force-quit it for maximum reliability.
