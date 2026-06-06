package com.alarmapp

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Persists scheduled alarms to SharedPreferences as JSON so that:
 *   - BootReceiver can re-arm them after a reboot (PendingIntents are wiped
 *     by the OS on reboot).
 *   - AlarmReceiver can recompute the next trigger for repeating alarms.
 *
 * This is intentionally a tiny hand-rolled JSON store (no extra deps). The
 * payload mirrors the Dart AlarmSchedule contract.
 */
object AlarmStore {

    data class StoredAlarm(
        val id: String,
        val label: String,
        val time: String,                 // "HH:mm"
        val repeatDays: List<Int>,         // 0=Sun..6=Sat, empty => one-shot
        val isActive: Boolean,
        val sound: String,
        val vibration: Boolean,
        val volume: Double,
        val snoozeEnabled: Boolean,
        val snoozeIntervalMin: Int,
        val snoozeLimit: Int,
    ) {
        fun toJson(): JSONObject = JSONObject().apply {
            put(AlarmContract.EXTRA_ID, id)
            put(AlarmContract.EXTRA_LABEL, label)
            put(AlarmContract.EXTRA_TIME, time)
            put(AlarmContract.EXTRA_REPEAT_DAYS, JSONArray(repeatDays))
            put(AlarmContract.EXTRA_SNOOZE_ENABLED, snoozeEnabled)
            put("isActive", isActive)
            put(AlarmContract.EXTRA_SOUND, sound)
            put(AlarmContract.EXTRA_VIBRATION, vibration)
            put(AlarmContract.EXTRA_VOLUME, volume)
            put(AlarmContract.EXTRA_SNOOZE_INTERVAL_MIN, snoozeIntervalMin)
            put(AlarmContract.EXTRA_SNOOZE_LIMIT, snoozeLimit)
        }

        companion object {
            fun fromJson(o: JSONObject): StoredAlarm {
                val days = mutableListOf<Int>()
                o.optJSONArray(AlarmContract.EXTRA_REPEAT_DAYS)?.let { arr ->
                    for (i in 0 until arr.length()) days.add(arr.getInt(i))
                }
                return StoredAlarm(
                    id = o.getString(AlarmContract.EXTRA_ID),
                    label = o.optString(AlarmContract.EXTRA_LABEL, "Alarm"),
                    time = o.getString(AlarmContract.EXTRA_TIME),
                    repeatDays = days,
                    isActive = o.optBoolean("isActive", true),
                    sound = o.optString(AlarmContract.EXTRA_SOUND, "default"),
                    vibration = o.optBoolean(AlarmContract.EXTRA_VIBRATION, true),
                    volume = o.optDouble(AlarmContract.EXTRA_VOLUME, 1.0),
                    snoozeEnabled = o.optBoolean(AlarmContract.EXTRA_SNOOZE_ENABLED, true),
                    snoozeIntervalMin = o.optInt(AlarmContract.EXTRA_SNOOZE_INTERVAL_MIN, 5),
                    snoozeLimit = o.optInt(AlarmContract.EXTRA_SNOOZE_LIMIT, 3),
                )
            }
        }
    }

    private fun prefs(ctx: Context) =
        ctx.getSharedPreferences(AlarmContract.PREFS, Context.MODE_PRIVATE)

    fun all(ctx: Context): List<StoredAlarm> {
        val raw = prefs(ctx).getString(AlarmContract.PREFS_KEY_ALARMS, "[]") ?: "[]"
        val arr = JSONArray(raw)
        return (0 until arr.length()).map { StoredAlarm.fromJson(arr.getJSONObject(it)) }
    }

    fun get(ctx: Context, id: String): StoredAlarm? = all(ctx).firstOrNull { it.id == id }

    /** Insert or replace by id, then persist. */
    fun upsert(ctx: Context, alarm: StoredAlarm) {
        val list = all(ctx).filter { it.id != alarm.id }.toMutableList()
        list.add(alarm)
        persist(ctx, list)
    }

    fun remove(ctx: Context, id: String) {
        persist(ctx, all(ctx).filter { it.id != id })
    }

    private fun persist(ctx: Context, list: List<StoredAlarm>) {
        val arr = JSONArray()
        list.forEach { arr.put(it.toJson()) }
        prefs(ctx).edit().putString(AlarmContract.PREFS_KEY_ALARMS, arr.toString()).apply()
    }
}
