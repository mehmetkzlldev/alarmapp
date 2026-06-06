package com.alarmapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Catches the exact-alarm broadcast fired by AlarmManager.setAlarmClock and
 * immediately starts the foreground ringing service. This runs even if the app
 * process was killed — the OS recreates the process to deliver the broadcast.
 *
 * IMPORTANT: A BroadcastReceiver runs on the main thread with a very short
 * window (~10s) before the system can kill it. We do the bare minimum here:
 * start the foreground service and re-arm the next occurrence for repeating
 * alarms. All heavy work (audio/UI) happens in the service.
 */
class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(AlarmContract.EXTRA_ID) ?: run {
            Log.w(TAG, "AlarmReceiver fired with no id")
            return
        }
        Log.i(TAG, "Alarm fired: $id")

        val alarm = AlarmStore.get(context, id)
        if (alarm == null || !alarm.isActive) {
            Log.w(TAG, "Alarm $id missing or inactive; ignoring")
            return
        }

        // 1. Start the foreground service that plays sound + posts the
        //    full-screen intent. Use startForegroundService on O+.
        val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
            action = AlarmContract.ACTION_START_RINGING
            putExtra(AlarmContract.EXTRA_ID, alarm.id)
            putExtra(AlarmContract.EXTRA_LABEL, alarm.label)
            putExtra(AlarmContract.EXTRA_SOUND, alarm.sound)
            putExtra(AlarmContract.EXTRA_VIBRATION, alarm.vibration)
            putExtra(AlarmContract.EXTRA_VOLUME, alarm.volume)
            putExtra(AlarmContract.EXTRA_SNOOZE_ENABLED, alarm.snoozeEnabled)
            putExtra(AlarmContract.EXTRA_SNOOZE_INTERVAL_MIN, alarm.snoozeIntervalMin)
            putExtra(AlarmContract.EXTRA_SNOOZE_LIMIT, alarm.snoozeLimit)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // 2. Re-arm the next occurrence for repeating alarms. setAlarmClock is a
        //    one-shot, so repeating alarms must re-schedule themselves after
        //    each fire. One-shot alarms are left to be cleaned up by Dart.
        if (alarm.repeatDays.isNotEmpty()) {
            // Reuse the plugin's scheduling logic via a fresh instance helper.
            AlarmRescheduler.scheduleExact(context, alarm)
            Log.i(TAG, "Re-armed repeating alarm $id")
        }
    }

    companion object {
        private const val TAG = "AlarmReceiver"
    }
}
