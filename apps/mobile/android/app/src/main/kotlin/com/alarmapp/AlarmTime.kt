package com.alarmapp

import java.util.Calendar

/**
 * Pure time math for computing the next trigger instant from an alarm's
 * "HH:mm" time and repeatDays (0=Sun..6=Sat). Kept separate so it is easy to
 * reason about and unit-test.
 */
object AlarmTime {

    /**
     * Returns the epoch-millis of the next time this alarm should fire,
     * relative to [now]. For a one-shot alarm (empty [repeatDays]) it returns
     * the next occurrence of HH:mm today or tomorrow. For a repeating alarm it
     * returns the soonest matching weekday at HH:mm strictly in the future.
     */
    fun nextTriggerMillis(
        time: String,
        repeatDays: List<Int>,
        now: Calendar = Calendar.getInstance(),
    ): Long {
        val (hour, minute) = parseHhMm(time)

        // Start from today at HH:mm.
        val candidate = (now.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        if (repeatDays.isEmpty()) {
            // One-shot: today if still in the future, else tomorrow.
            if (candidate.timeInMillis <= now.timeInMillis) {
                candidate.add(Calendar.DAY_OF_YEAR, 1)
            }
            return candidate.timeInMillis
        }

        // Repeating: scan up to 7 days ahead for the next matching weekday.
        // Calendar.DAY_OF_WEEK is 1=Sunday..7=Saturday; our contract is 0..6.
        for (offset in 0..7) {
            val c = (candidate.clone() as Calendar).apply {
                add(Calendar.DAY_OF_YEAR, offset)
            }
            val dow = c.get(Calendar.DAY_OF_WEEK) - 1 // -> 0..6
            val inFuture = c.timeInMillis > now.timeInMillis
            if (repeatDays.contains(dow) && inFuture) {
                return c.timeInMillis
            }
        }
        // Should never happen (a repeating alarm always has a next day within
        // a week), but fall back to +1 day.
        return candidate.apply { add(Calendar.DAY_OF_YEAR, 1) }.timeInMillis
    }

    private fun parseHhMm(time: String): Pair<Int, Int> {
        val parts = time.split(":")
        require(parts.size == 2) { "Invalid time format: $time (expected HH:mm)" }
        val h = parts[0].toInt().coerceIn(0, 23)
        val m = parts[1].toInt().coerceIn(0, 59)
        return h to m
    }

    /** Stable positive int request code for a PendingIntent from a UUID string. */
    fun requestCode(id: String): Int = (id.hashCode() and 0x7fffffff)
}
