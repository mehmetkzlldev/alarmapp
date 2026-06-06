# iOS Build Guide (must be done on a Mac)

The iOS project is **prepared** (Xcode project scaffolded, native Swift alarm code
in place, Info.plist permissions + background audio + Turkish/English locales set,
classic app lifecycle so the channel-wiring AppDelegate works). It was prepared on
**Windows, where iOS apps cannot be built or tested** — Xcode is macOS-only. Finish
and run it on a Mac (or a cloud-Mac CI like **Codemagic**, which has a free tier).

## What was already done (on Windows)
- `flutter create . --platforms=ios --org com.alarmapp` → `Runner.xcodeproj`, `Info.plist`, storyboards, assets.
- Native engine kept: `ios/Runner/AppDelegate.swift` (MethodChannel/EventChannel `app/alarm`), `ios/Runner/AlarmManager.swift` (local-notification + background-audio alarm), `ios/Runner/Runner.entitlements` (critical alerts + aps-environment).
- `Info.plist`: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription`, `UIBackgroundModes: [audio]`, `CFBundleLocalizations: [en, tr]`, display name "AI Alarm", and the **scene manifest removed** (classic lifecycle so `AppDelegate.window` is valid).

## Steps on the Mac
1. **Install tooling**: Xcode + CocoaPods (`sudo gem install cocoapods`), and Flutter.
2. From `apps/mobile`: `flutter pub get`
3. `cd ios && pod install` (creates `Podfile`/`Podfile.lock`, installs the plugin pods). If there is no `Podfile`, run `flutter build ios --config-only` first — it generates one.
4. Open **`ios/Runner.xcworkspace`** (the *workspace*, not the project) in Xcode.
5. **⚠️ Add `AlarmManager.swift` to the Runner target** — it sits in `ios/Runner/` but is NOT yet in the build target (it could not be added without Xcode). In the Project navigator: right-click the **Runner** group → *Add Files to "Runner"…* → pick `AlarmManager.swift` → make sure the **Runner** target checkbox is on. (Without this the build fails: "cannot find AlarmManager in scope".)
6. **Signing**: select the *Runner* target → *Signing & Capabilities* → set your **Team** and a unique **Bundle Identifier** (e.g. `com.yourname.aialarm`).
7. **Capabilities** (Signing & Capabilities → "+ Capability"): add **Background Modes** (check *Audio, AirPlay, and Picture in Picture*) and **Push Notifications**.
8. **Critical Alerts** (optional, for alarms that pierce silent/DND): the entitlement is already in `Runner.entitlements`, but Apple must approve it — request at
   https://developer.apple.com/contact/request/notifications-critical-alerts-entitlement/ .
   Until approved, alarms ring as normal high-priority notifications.
9. **Backend URL**: build with your backend baked in, e.g.
   `flutter run --dart-define=API_BASE_URL=https://your-backend.example.com/api/v1`
   - For LOCAL testing against the dev backend over HTTP, iOS blocks cleartext by default (ATS). Either deploy the backend over HTTPS, or add a **dev-only** ATS exception to `Info.plist` (`NSAppTransportSecurity → NSAllowsArbitraryLoads = true`). Remove it for release.
10. **Run**: select a device/simulator → `flutter run` (or Xcode ▶︎). For a distributable build: `flutter build ipa`.

## iOS alarm reality (important — read ios/ALARM_README.md)
iOS has **no exact background execution** like Android's `AlarmManager`. The native
side schedules **local notifications** (critical alerts when approved) and plays
looping **background audio**. So:
- The Android-style full-screen lock-screen ring is **not possible** on iOS. iOS shows a notification; tapping it opens the ring/mission screen.
- Reliability depends on Apple's notification delivery + critical-alert approval. It is inherently less guaranteed than Android's foreground-service alarm.

## If the app crashes on launch
The `AppDelegate` wires the channels using `window?.rootViewController`. We reverted
to the classic (non-scene) lifecycle for this. If you prefer to keep Apple's newer
UIScene lifecycle, move the channel registration into `SceneDelegate.swift`
(`scene(_:willConnectTo:options:)`, using the scene's `FlutterViewController`) instead.
