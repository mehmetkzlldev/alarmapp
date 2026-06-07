# iOS Build Guide — WakeUp AI

The iOS project is **buildable**. The Dart/Flutter code is cross-platform (all the
new features — onboarding, Mango theme, AI designer, etc. — already work on iOS),
the native Swift alarm engine is consistent, and the one Xcode-target blocker has
been fixed (`AlarmManager.swift` is now a member of the Runner target).

You still cannot build iOS **on Windows** (Xcode is macOS-only), but you have two
ways to get a build without owning a Mac.

## ✅ Already done (on Windows)
- `flutter create . --platforms=ios` scaffold; `Runner.xcodeproj`, Info.plist.
- Native engine: `AppDelegate.swift` (channels) + `AlarmManager.swift` (local-notif
  + background audio) + `Runner.entitlements` (critical alerts). **AlarmManager.swift
  added to the Runner build target** via the `xcode` tool (was the only build blocker).
- Info.plist: display name **WakeUp AI**, camera/mic/photo perms, `UIBackgroundModes:
  audio`, `CFBundleLocalizations [en, tr]`, classic (non-scene) app lifecycle.
- New **WakeUp AI sunrise launcher icon** generated for iOS (flutter_launcher_icons).
- **`codemagic.yaml`** at the repo root → cloud builds, no Mac needed.

---

## Path A — Codemagic (cloud Mac CI, no Mac needed)
1. Sign up at **https://codemagic.io** (free tier; sign in with GitHub).
2. Add the repo **mehmetkzlldev/alarmapp**. Codemagic auto-detects `codemagic.yaml`.
3. Run the **`ios-unsigned`** workflow → it compiles the iOS app on a real Mac with
   **no Apple account**. This proves the whole thing builds. Output: a `.app`
   (NOT installable on a device — it's a compile check).
4. To get an **installable IPA** you must sign it → see "Installing on a real
   iPhone" below.

## Path B — A Mac
1. `flutter pub get`, then `cd ios && pod install` (generates the Podfile + pods).
2. Open `ios/Runner.xcworkspace` in Xcode, set your **Team** + a unique **Bundle
   Identifier**, then Run on a device/simulator.

---

## 📲 Installing on a REAL iPhone (the honest part)
Apple locks this down — unlike Android, you can't just download an IPA and tap
install. You need ONE of:
- **Apple Developer Program ($99/yr)** + Codemagic signing → build a signed IPA →
  distribute via TestFlight or ad-hoc. (Uncomment the `ios-release` workflow in
  `codemagic.yaml` and add your signing.)
- **A Mac + a free Apple ID** → Xcode installs to your own iPhone (free, but the
  app expires after 7 days).
- **A signed IPA + Sideloadly (on Windows)** → sideload to your iPhone with a free
  Apple ID (7-day expiry, fiddly). Still needs the IPA built+signed somewhere.

There is no way around having *some* Apple account to run on a physical iPhone.

---

## Remaining Mac-side refinements (not build blockers)
- **Firebase**: `firebase_options.dart` is a placeholder + no `GoogleService-Info.plist`.
  The app **boots fine without it** (main.dart guards Firebase init) — push/Crashlytics
  are just disabled. For those features, run `flutterfire configure` on a Mac.
- **Native alarm sound**: `AlarmManager.swift` expects a bundled `.caf` sound; our
  `alarm.wav` isn't bundled for native iOS yet, so the iOS alarm may use the default
  sound. Convert + add it in Xcode (Copy Bundle Resources) on a Mac if you want the
  custom tone.
- **Critical-alerts entitlement** needs Apple approval (request form in ALARM_README.md).
- iOS has no exact background alarm execution like Android — see `ALARM_README.md`.
