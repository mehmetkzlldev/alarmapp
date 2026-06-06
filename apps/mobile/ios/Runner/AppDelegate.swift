import UIKit
import Flutter
import UserNotifications

/// AppDelegate wired for the alarm engine.
///
/// Adds:
///   - MethodChannel 'app/alarm' handling (schedule/cancel/snooze/stop/etc.)
///     delegating to AlarmManager.
///   - EventChannel 'app/alarm/events' that streams 'alarm_fired' to Dart.
///   - UNUserNotificationCenterDelegate so notifications show while the app is
///     foreground AND so tapping an alarm notification starts ringing + routes
///     the Flutter UI to the ring screen.
@main
@objc class AppDelegate: FlutterAppDelegate {

    private var methodChannel: FlutterMethodChannel?
    private var eventSink: FlutterEventSink?
    /// Buffers an 'alarm_fired' event that arrives before Dart subscribes
    /// (e.g. cold launch from a notification tap), so it is not lost.
    private var pendingEvent: [String: Any]?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let messenger = controller.binaryMessenger

        // --- MethodChannel 'app/alarm' ---
        let channel = FlutterMethodChannel(name: "app/alarm", binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
        methodChannel = channel

        // --- EventChannel 'app/alarm/events' ---
        let events = FlutterEventChannel(name: "app/alarm/events", binaryMessenger: messenger)
        events.setStreamHandler(self)

        // We are the notification delegate so we can intercept fires/taps.
        UNUserNotificationCenter.current().delegate = self
        registerNotificationCategories()

        // Ask for notification (incl. critical alert) authorization up front.
        AlarmManager.shared.requestAuthorization { granted in
            NSLog("Alarm notification authorization granted: \(granted)")
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - MethodChannel handling

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "schedule":
            if let args = call.arguments as? [String: Any] {
                AlarmManager.shared.schedule(args)
            }
            result(nil)

        case "cancel":
            if let id = (call.arguments as? [String: Any])?["id"] as? String {
                AlarmManager.shared.cancel(id: id)
            }
            result(nil)

        case "snooze":
            if let args = call.arguments as? [String: Any],
               let id = args["id"] as? String {
                let delay = args["delayMinutes"] as? Int ?? 5
                AlarmManager.shared.snooze(id: id, delayMinutes: delay)
                emit(type: "alarm_snoozed", alarmId: id)
            }
            result(nil)

        case "stop":
            if let id = (call.arguments as? [String: Any])?["id"] as? String {
                AlarmManager.shared.stopRinging()
                emit(type: "alarm_stopped", alarmId: id)
            }
            result(nil)

        case "canScheduleExactAlarms":
            // iOS has no exact-alarm permission concept; always "true".
            result(true)

        case "requestExactAlarmPermission":
            // No-op on iOS.
            result(nil)

        case "requestIgnoreBatteryOptimizations":
            // No-op on iOS.
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Event bridge

    private func emit(type: String, alarmId: String, extra: [String: Any] = [:]) {
        var payload: [String: Any] = ["type": type, "alarmId": alarmId]
        payload.merge(extra) { _, new in new }
        if let sink = eventSink {
            sink(payload)
        } else {
            // Buffer until Dart subscribes (cold-launch from notification tap).
            pendingEvent = payload
        }
    }

    // MARK: - Notification categories

    private func registerNotificationCategories() {
        let snooze = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [snooze],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

// MARK: - FlutterStreamHandler (EventChannel)

extension AppDelegate: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        if let pending = pendingEvent {
            events(pending)
            pendingEvent = nil
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate {

    /// Called when a notification is delivered while the app is in the
    /// FOREGROUND. We present it (banner + sound) AND immediately start the
    /// looping ring audio + route to the ring screen, since the user is here.
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let info = notification.request.content.userInfo
        if let alarmId = info["alarmId"] as? String {
            beginRinging(alarmId: alarmId, userInfo: info)
        }
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .list])
        } else {
            completionHandler([.alert, .sound])
        }
    }

    /// Called when the user TAPS the notification (or its actions), including a
    /// cold launch. We start ringing and route the Flutter UI to /alarm-ring.
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let info = response.notification.request.content.userInfo
        guard let alarmId = info["alarmId"] as? String else {
            completionHandler(); return
        }

        if response.actionIdentifier == "SNOOZE_ACTION" {
            AlarmManager.shared.snooze(id: alarmId, delayMinutes: 5)
            emit(type: "alarm_snoozed", alarmId: alarmId)
        } else {
            beginRinging(alarmId: alarmId, userInfo: info)
        }
        completionHandler()
    }

    /// Shared path: start looping audio and tell Dart the alarm fired so it can
    /// navigate to the full-screen ring route.
    private func beginRinging(alarmId: String, userInfo: [AnyHashable: Any]) {
        let volume = userInfo["volume"] as? Double ?? 1.0
        AlarmManager.shared.startRinging(alarmId: alarmId, soundName: "default", volume: volume)
        emit(type: "alarm_fired", alarmId: alarmId)
    }
}
