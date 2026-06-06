package com.alarmapp

/**
 * Shared constants for the Android alarm engine. Keys here MUST match the
 * Dart-side AlarmSchedule.toMap() contract and the MethodChannel method names
 * in alarm_scheduler_impl.dart. Do not rename without updating Dart.
 */
object AlarmContract {
    // MethodChannel / EventChannel names (must match Dart).
    const val METHOD_CHANNEL = "app/alarm"
    const val EVENT_CHANNEL = "app/alarm/events"

    // MethodChannel methods.
    const val M_SCHEDULE = "schedule"
    const val M_CANCEL = "cancel"
    const val M_SNOOZE = "snooze"
    const val M_STOP = "stop"
    const val M_CAN_SCHEDULE_EXACT = "canScheduleExactAlarms"
    const val M_REQUEST_EXACT = "requestExactAlarmPermission"
    const val M_REQUEST_BATTERY = "requestIgnoreBatteryOptimizations"

    // Intent extras (passed from scheduler -> receiver -> service -> activity).
    const val EXTRA_ID = "id"
    const val EXTRA_LABEL = "label"
    const val EXTRA_TIME = "time"
    const val EXTRA_REPEAT_DAYS = "repeatDays"
    const val EXTRA_SOUND = "sound"
    const val EXTRA_VIBRATION = "vibration"
    const val EXTRA_VOLUME = "volume"
    const val EXTRA_SNOOZE_ENABLED = "snoozeEnabled"
    const val EXTRA_SNOOZE_INTERVAL_MIN = "snoozeIntervalMin"
    const val EXTRA_SNOOZE_LIMIT = "snoozeLimit"

    // Event payload keys (must match Dart AlarmEvent.fromMap).
    const val EVENT_TYPE = "type"
    const val EVENT_ALARM_ID = "alarmId"
    const val EVENT_FIRED = "alarm_fired"
    const val EVENT_SNOOZED = "alarm_snoozed"
    const val EVENT_STOPPED = "alarm_stopped"

    // Foreground service actions.
    const val ACTION_START_RINGING = "com.alarmapp.action.START_RINGING"
    const val ACTION_STOP_RINGING = "com.alarmapp.action.STOP_RINGING"

    // Notification.
    const val CHANNEL_ID = "alarm_ring_channel"
    const val CHANNEL_NAME = "Alarms"
    const val FOREGROUND_NOTIFICATION_ID = 4242

    // The GoRouter route the Flutter engine should open when launched cold.
    const val RING_ROUTE = "/alarm-ring"

    // SharedPreferences store used to persist alarms for reboot rescheduling.
    const val PREFS = "alarm_store"
    const val PREFS_KEY_ALARMS = "alarms_json"
}
