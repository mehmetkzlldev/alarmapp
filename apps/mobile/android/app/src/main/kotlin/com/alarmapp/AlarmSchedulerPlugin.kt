package com.alarmapp

import android.app.Activity
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannel/EventChannel handler for 'app/alarm'.
 *
 * Responsibilities:
 *   - schedule/cancel/snooze/stop exact OS alarms using AlarmManager.setAlarmClock
 *     (the most reliable API: it is exempt from Doze and shows the system alarm
 *     icon; the user perceives it as a real clock alarm).
 *   - Persist alarms via AlarmStore for reboot rescheduling.
 *   - Bridge native alarm events up to Dart over the EventChannel. Because the
 *     alarm can fire while the Flutter engine is dead, we keep a static
 *     reference to the active EventSink and replay the last pending event on
 *     (re)subscription.
 */
class AlarmSchedulerPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var appContext: Context
    private var activity: Activity? = null
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    // region FlutterPlugin
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, AlarmContract.METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, AlarmContract.EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
    // endregion

    // region ActivityAware
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(b: ActivityPluginBinding) { activity = b.activity }
    override fun onDetachedFromActivity() { activity = null }
    // endregion

    // region EventChannel
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        // Replay any event that fired before Dart subscribed (cold start).
        pendingEvent?.let { events?.success(it); pendingEvent = null }
    }

    override fun onCancel(arguments: Any?) { eventSink = null }
    // endregion

    // region MethodChannel
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            AlarmContract.M_SCHEDULE -> {
                val alarm = readAlarm(call)
                AlarmStore.upsert(appContext, alarm)
                scheduleExact(appContext, alarm)
                result.success(null)
            }

            AlarmContract.M_CANCEL -> {
                val id = call.argument<String>("id")!!
                cancel(appContext, id)
                AlarmStore.remove(appContext, id)
                result.success(null)
            }

            AlarmContract.M_SNOOZE -> {
                val id = call.argument<String>("id")!!
                val delayMin = call.argument<Int>("delayMinutes") ?: 5
                // Stop the current ring, then re-arm a one-shot trigger.
                stopRinging(appContext, id)
                scheduleSnooze(appContext, id, delayMin)
                result.success(null)
            }

            AlarmContract.M_STOP -> {
                val id = call.argument<String>("id")!!
                stopRinging(appContext, id)
                result.success(null)
            }

            AlarmContract.M_CAN_SCHEDULE_EXACT -> result.success(canScheduleExact())

            AlarmContract.M_REQUEST_EXACT -> {
                requestExactAlarmPermission()
                result.success(null)
            }

            AlarmContract.M_REQUEST_BATTERY -> {
                requestIgnoreBatteryOptimizations()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }
    // endregion

    // region Scheduling
    private fun alarmManager(ctx: Context) =
        ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    /**
     * Arms an exact alarm using setAlarmClock — the gold standard for alarm
     * apps. It is NOT deferred by Doze, surfaces the lock-screen alarm icon,
     * and gives the user a "show" intent to the app. Delegates to
     * AlarmRescheduler so schedule/cancel PendingIntents stay identical across
     * the plugin, the receiver, and the boot receiver.
     */
    fun scheduleExact(ctx: Context, alarm: AlarmStore.StoredAlarm) {
        if (!alarm.isActive) { cancel(ctx, alarm.id); return }
        AlarmRescheduler.scheduleExact(ctx, alarm)
    }

    /** One-shot re-arm N minutes from now for a snooze. */
    private fun scheduleSnooze(ctx: Context, id: String, delayMinutes: Int) {
        // Ensure the alarm still exists in the store; ignore stale snooze calls.
        AlarmStore.get(ctx, id) ?: return
        val triggerAt = System.currentTimeMillis() + delayMinutes * 60_000L
        AlarmRescheduler.scheduleExactAt(ctx, id, triggerAt)
        emit(AlarmContract.EVENT_SNOOZED, id)
    }

    fun cancel(ctx: Context, id: String) {
        val intent = Intent(ctx, AlarmReceiver::class.java).apply {
            action = AlarmContract.ACTION_START_RINGING
        }
        val pi = PendingIntent.getBroadcast(
            ctx,
            AlarmTime.requestCode(id),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager(ctx).cancel(pi)
    }

    /** Stop the foreground ringing service for [id]. */
    private fun stopRinging(ctx: Context, id: String) {
        val stop = Intent(ctx, AlarmForegroundService::class.java).apply {
            action = AlarmContract.ACTION_STOP_RINGING
            putExtra(AlarmContract.EXTRA_ID, id)
        }
        ctx.startService(stop)
        emit(AlarmContract.EVENT_STOPPED, id)
    }
    // endregion

    // region Permissions
    private fun canScheduleExact(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager(appContext).canScheduleExactAlarms()
        } else true
    }

    private fun requestExactAlarmPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !canScheduleExact()) {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.parse("package:${appContext.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            (activity ?: appContext.also { intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) })
                .startActivity(intent)
        }
    }

    private fun requestIgnoreBatteryOptimizations() {
        val pm = appContext.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!pm.isIgnoringBatteryOptimizations(appContext.packageName)) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${appContext.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            (activity ?: appContext).startActivity(intent)
        }
    }
    // endregion

    private fun readAlarm(call: MethodCall): AlarmStore.StoredAlarm {
        @Suppress("UNCHECKED_CAST")
        val days = (call.argument<List<Int>>(AlarmContract.EXTRA_REPEAT_DAYS) ?: emptyList())
        return AlarmStore.StoredAlarm(
            id = call.argument<String>(AlarmContract.EXTRA_ID)!!,
            label = call.argument<String>(AlarmContract.EXTRA_LABEL) ?: "Alarm",
            time = call.argument<String>(AlarmContract.EXTRA_TIME)!!,
            repeatDays = days,
            isActive = call.argument<Boolean>("isActive") ?: true,
            sound = call.argument<String>(AlarmContract.EXTRA_SOUND) ?: "default",
            vibration = call.argument<Boolean>(AlarmContract.EXTRA_VIBRATION) ?: true,
            volume = call.argument<Double>(AlarmContract.EXTRA_VOLUME) ?: 1.0,
            snoozeEnabled = call.argument<Boolean>(AlarmContract.EXTRA_SNOOZE_ENABLED) ?: true,
            snoozeIntervalMin = call.argument<Int>(AlarmContract.EXTRA_SNOOZE_INTERVAL_MIN) ?: 5,
            snoozeLimit = call.argument<Int>(AlarmContract.EXTRA_SNOOZE_LIMIT) ?: 3,
        )
    }

    companion object {
        // Held statically so native components (service/activity) can push
        // events up even when the plugin instance is mid-lifecycle, and so a
        // cold-started engine can replay the alarm that woke it.
        @Volatile private var eventSink: EventChannel.EventSink? = null
        @Volatile private var pendingEvent: Map<String, Any?>? = null

        /** Emit an event to Dart, buffering it if Dart hasn't subscribed yet. */
        fun emit(type: String, alarmId: String, extra: Map<String, Any?> = emptyMap()) {
            val payload = HashMap<String, Any?>().apply {
                put(AlarmContract.EVENT_TYPE, type)
                put(AlarmContract.EVENT_ALARM_ID, alarmId)
                putAll(extra)
            }
            val sink = eventSink
            if (sink != null) {
                sink.success(payload)
            } else {
                // Buffer the most recent fire so a cold engine doesn't miss it.
                pendingEvent = payload
            }
        }
    }
}
