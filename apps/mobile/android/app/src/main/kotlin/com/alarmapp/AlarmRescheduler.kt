package com.alarmapp

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

/**
 * Single source of truth for arming an exact alarm. Used by:
 *   - AlarmReceiver (to re-arm repeating alarms after each fire),
 *   - BootReceiver (to re-arm everything after reboot),
 *   - AlarmSchedulerPlugin delegates the heavy lifting here too.
 *
 * Keeping this in one object avoids drift between the three call sites — they
 * MUST build identical PendingIntents (same request code + flags) so cancel()
 * matches schedule().
 */
object AlarmRescheduler {

    fun scheduleExact(ctx: Context, alarm: AlarmStore.StoredAlarm) {
        if (!alarm.isActive) return
        val triggerAt = AlarmTime.nextTriggerMillis(alarm.time, alarm.repeatDays)
        scheduleExactAt(ctx, alarm.id, triggerAt)
    }

    /**
     * Arm an exact alarm for [id] at an explicit [triggerAtMillis]. Used both by
     * [scheduleExact] (recurring/next time) and by snooze (now + delay). The
     * fire + show PendingIntents are constructed identically everywhere.
     */
    fun scheduleExactAt(ctx: Context, id: String, triggerAtMillis: Long) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val firePi = PendingIntent.getBroadcast(
            ctx,
            AlarmTime.requestCode(id),
            Intent(ctx, AlarmReceiver::class.java).apply {
                action = AlarmContract.ACTION_START_RINGING
                putExtra(AlarmContract.EXTRA_ID, id)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val showPi = PendingIntent.getActivity(
            ctx,
            AlarmTime.requestCode(id) xor 0x55,
            Intent(ctx, AlarmActivity::class.java)
                .putExtra(AlarmContract.EXTRA_ID, id),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        am.setAlarmClock(AlarmManager.AlarmClockInfo(triggerAtMillis, showPi), firePi)
    }
}
