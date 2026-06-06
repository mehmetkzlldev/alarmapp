import Foundation
import UserNotifications
import AVFoundation

/// iOS alarm engine.
///
/// IMPORTANT iOS REALITY CHECK: iOS does **not** allow apps to run arbitrary
/// background code at a scheduled time the way Android's AlarmManager +
/// foreground service does. There is no exact-alarm broadcast that wakes a dead
/// app to start playing audio. We therefore combine two mechanisms:
///
///   1. UNUserNotificationCenter local notifications (optionally **Critical
///      Alerts**) scheduled for each alarm occurrence. Critical alerts bypass
///      silent mode / Focus and play a sound even when the device is muted —
///      this is the closest iOS gets to a "real" alarm and requires a special
///      Apple-granted entitlement.
///
///   2. A looping AVAudioPlayer using the `.playback` audio session category
///      with background audio enabled, started when the app is foregrounded by
///      the notification (or kept alive if the app was already running). This
///      lets the alarm sound loop continuously and ignore the mute switch once
///      audio is playing.
///
/// See ALARM_README.md for the full caveats and entitlement setup.
@objc class AlarmManager: NSObject {

    static let shared = AlarmManager()

    /// Identifier prefix for our notification requests so we can find/cancel
    /// them. Each occurrence id is "<prefix>.<alarmId>.<occurrenceIndex>".
    private let idPrefix = "com.alarmapp.alarm"

    /// How many future occurrences to pre-schedule for a repeating alarm.
    /// iOS caps an app at 64 pending local notifications, so we schedule a
    /// rolling window and top it up whenever the app is opened.
    private let maxOccurrencesPerAlarm = 8

    private var audioPlayer: AVAudioPlayer?
    private(set) var ringingAlarmId: String?

    // MARK: - Permissions

    /// Request notification authorization, including the Critical Alerts option.
    /// `.criticalAlert` only takes effect if the app ships the
    /// `com.apple.developer.usernotifications.critical-alerts` entitlement
    /// (Apple-approved). Without it the option is ignored and we fall back to a
    /// normal time-sensitive alert.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        var options: UNAuthorizationOptions = [.alert, .sound, .badge]
        options.insert(.criticalAlert)
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if let error = error {
                NSLog("AlarmManager auth error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async { completion(granted) }
        }
    }

    // MARK: - Scheduling

    /// Schedule (or reschedule) an alarm. Cancels any existing occurrences for
    /// the same alarm id first, then schedules a rolling window of future fires.
    ///
    /// - Parameters:
    ///   - alarm: the alarm config map mirroring the Dart AlarmSchedule contract.
    func schedule(_ alarm: [String: Any]) {
        guard let id = alarm["id"] as? String,
              let time = alarm["time"] as? String,
              let isActive = alarm["isActive"] as? Bool else {
            NSLog("AlarmManager.schedule: invalid alarm payload")
            return
        }

        // Inactive alarms must not leave pending notifications.
        cancel(id: id)
        guard isActive else { return }

        let label = alarm["label"] as? String ?? "Alarm"
        let repeatDays = alarm["repeatDays"] as? [Int] ?? []
        let soundName = alarm["sound"] as? String ?? "default"
        let volume = alarm["volume"] as? Double ?? 1.0

        let occurrences = nextOccurrences(time: time, repeatDays: repeatDays,
                                          count: maxOccurrencesPerAlarm)

        let center = UNUserNotificationCenter.current()
        for (index, comps) in occurrences.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = label.isEmpty ? "Alarm" : label
            content.body = "Tap to complete your mission and stop the alarm."
            content.categoryIdentifier = "ALARM_CATEGORY"
            content.userInfo = ["alarmId": id, "volume": volume]

            // Critical sound bypasses mute/Focus when the entitlement is present.
            content.sound = criticalSound(named: soundName)
            // Time-sensitive interruption so it surfaces through Focus modes.
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .critical
            }

            // Calendar trigger: repeats weekly for repeating alarms (so the OS
            // keeps re-firing without us), one-shot otherwise.
            let repeats = !repeatDays.isEmpty && occurrencesAreWeekday(comps)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: repeats)

            let reqId = "\(idPrefix).\(id).\(index)"
            let request = UNNotificationRequest(identifier: reqId, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    NSLog("AlarmManager add request failed: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Cancel all pending notifications for an alarm id.
    func cancel(id: String) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix("\(self.idPrefix).\(id).") }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// Snooze: stop current audio and schedule a one-shot notification N minutes
    /// out. We do NOT remove the recurring schedule (so the regular alarm still
    /// fires next day for repeating alarms).
    func snooze(id: String, delayMinutes: Int) {
        stopRinging()

        let content = UNMutableNotificationContent()
        content.title = "Alarm (snoozed)"
        content.body = "Tap to complete your mission and stop the alarm."
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.userInfo = ["alarmId": id]
        content.sound = criticalSound(named: "default")
        if #available(iOS 15.0, *) { content.interruptionLevel = .critical }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(max(1, delayMinutes) * 60),
            repeats: false
        )
        let reqId = "\(idPrefix).\(id).snooze"
        let request = UNNotificationRequest(identifier: reqId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // MARK: - Ringing audio (foreground / background-audio)

    /// Begin looping alarm audio. Called when the notification delivers while
    /// the app is alive/foregrounded, or when the user taps the notification and
    /// the app launches onto the ring screen.
    func startRinging(alarmId: String, soundName: String, volume: Double) {
        ringingAlarmId = alarmId
        configureAudioSessionForAlarm()

        guard let url = soundURL(named: soundName) else {
            NSLog("AlarmManager: no sound url for \(soundName)")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // Loop forever until stopped.
            player.volume = Float(min(max(volume, 0.0), 1.0))
            player.prepareToPlay()
            player.play()
            audioPlayer = player
        } catch {
            NSLog("AlarmManager: failed to start audio: \(error.localizedDescription)")
        }
    }

    /// Stop the looping audio and deactivate the audio session.
    func stopRinging() {
        audioPlayer?.stop()
        audioPlayer = nil
        ringingAlarmId = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    /// Configure the shared audio session so alarm audio:
    ///   - plays in the background (Background Modes > Audio capability),
    ///   - ignores the silent switch (`.playback` category),
    ///   - mixes appropriately. We use `.playback` (not `.ambient`) so the mute
    ///     switch is ignored once audio is actually playing.
    private func configureAudioSessionForAlarm() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: [.duckOthers])
            try session.setActive(true, options: [])
        } catch {
            NSLog("AlarmManager: audio session error: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    /// Build a critical sound when possible (bypasses mute/Focus), else default.
    private func criticalSound(named soundName: String) -> UNNotificationSound {
        if soundName.isEmpty || soundName == "default" {
            // Critical version of the default sound. If the entitlement is
            // absent, iOS treats this as the normal default sound.
            return UNNotificationSound.defaultCritical
        }
        let file = soundName.hasSuffix(".caf") ? soundName : "\(soundName).caf"
        return UNNotificationSound.criticalSoundNamed(
            UNNotificationSoundName(rawValue: file)
        )
    }

    /// Resolve a bundled sound resource URL for AVAudioPlayer. Custom sounds are
    /// bundled .caf/.mp3 files; "default" falls back to a bundled looping tone.
    private func soundURL(named soundName: String) -> URL? {
        let name = (soundName.isEmpty || soundName == "default") ? "alarm_default" : soundName
        for ext in ["caf", "mp3", "wav", "m4a"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        // Last resort: the default bundled tone.
        return Bundle.main.url(forResource: "alarm_default", withExtension: "caf")
    }

    /// Compute the next [count] DateComponents at which the alarm should fire.
    /// For repeating alarms we emit one weekly-matching component per selected
    /// weekday (the trigger then repeats weekly). For one-shot alarms we emit a
    /// single fully-specified date.
    private func nextOccurrences(time: String, repeatDays: [Int], count: Int) -> [DateComponents] {
        let parts = time.split(separator: ":")
        let hour = parts.count > 0 ? Int(parts[0]) ?? 7 : 7
        let minute = parts.count > 1 ? Int(parts[1]) ?? 0 : 0

        if repeatDays.isEmpty {
            // One-shot: next occurrence of HH:mm.
            var comps = DateComponents()
            comps.hour = hour
            comps.minute = minute
            let cal = Calendar.current
            if let next = cal.nextDate(after: Date(), matching: comps,
                                       matchingPolicy: .nextTime) {
                return [cal.dateComponents([.year, .month, .day, .hour, .minute], from: next)]
            }
            return [comps]
        }

        // Repeating: one weekly trigger per selected weekday.
        // Our contract: 0=Sun..6=Sat. iOS weekday: 1=Sun..7=Sat.
        return repeatDays.prefix(count).map { day -> DateComponents in
            var comps = DateComponents()
            comps.weekday = day + 1
            comps.hour = hour
            comps.minute = minute
            return comps
        }
    }

    private func occurrencesAreWeekday(_ comps: DateComponents) -> Bool {
        comps.weekday != nil && comps.day == nil
    }
}
