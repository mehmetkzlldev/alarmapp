package com.alarmapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Re-arms all persisted alarms after the device reboots (or the app is
 * updated). Exact alarms scheduled with AlarmManager do NOT survive a reboot —
 * the OS clears all pending alarms — so we must reschedule from our persisted
 * AlarmStore.
 *
 * Triggered by ACTION_BOOT_COMPLETED (and a few OEM/quickboot variants) and by
 * MY_PACKAGE_REPLACED so alarms survive app updates too. Requires the
 * RECEIVE_BOOT_COMPLETED permission and a manifest <receiver> with the matching
 * intent-filter (see AndroidManifest snippet).
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                rescheduleAll(context)
            }
            else -> Log.d(TAG, "Ignoring action ${intent.action}")
        }
    }

    private fun rescheduleAll(context: Context) {
        val alarms = AlarmStore.all(context).filter { it.isActive }
        Log.i(TAG, "Rescheduling ${alarms.size} active alarms after boot/update")
        alarms.forEach { alarm ->
            try {
                AlarmRescheduler.scheduleExact(context, alarm)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to reschedule alarm ${alarm.id}", e)
            }
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}
