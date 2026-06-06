package com.alarmapp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log

/**
 * Foreground service that OWNS the ringing experience:
 *   - Acquires a partial WakeLock so the CPU stays awake even with screen off.
 *   - Plays the alarm sound on a loop via MediaPlayer (alarm audio stream, so
 *     it ignores the ringer/silent mode and uses the alarm volume).
 *   - Vibrates in a repeating pattern.
 *   - Posts a high-priority notification with a full-screen intent that
 *     launches AlarmActivity over the lock screen.
 *   - Emits 'alarm_fired' to Dart via the plugin's event bridge.
 *
 * A foreground service is the only reliable way to keep audio playing while the
 * app is backgrounded / the engine is dead. It must call startForeground()
 * within ~5s of being started, which we do immediately.
 */
class AlarmForegroundService : Service() {

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var currentAlarmId: String? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            AlarmContract.ACTION_STOP_RINGING -> {
                stopRinging()
                return START_NOT_STICKY
            }
            else -> startRinging(intent)
        }
        // START_STICKY: if the OS kills us under memory pressure, recreate so the
        // alarm keeps ringing until the user completes the mission.
        return START_STICKY
    }

    private fun startRinging(intent: Intent?) {
        val id = intent?.getStringExtra(AlarmContract.EXTRA_ID) ?: return
        val label = intent.getStringExtra(AlarmContract.EXTRA_LABEL) ?: "Alarm"
        val sound = intent.getStringExtra(AlarmContract.EXTRA_SOUND) ?: "default"
        val vibration = intent.getBooleanExtra(AlarmContract.EXTRA_VIBRATION, true)
        val volume = intent.getDoubleExtra(AlarmContract.EXTRA_VOLUME, 1.0)
        currentAlarmId = id

        // 1. Go foreground IMMEDIATELY with a full-screen-intent notification.
        createChannel()
        startForeground(AlarmContract.FOREGROUND_NOTIFICATION_ID, buildNotification(id, label))

        // 2. Hold a wake lock so the CPU keeps running with the screen off.
        acquireWakeLock()

        // 3. Start audio + vibration.
        startAudio(sound, volume)
        if (vibration) startVibration()

        // 4. Notify Dart that the alarm fired (buffered if engine is cold).
        AlarmSchedulerPlugin.emit(AlarmContract.EVENT_FIRED, id)

        // 5. Launch the lock-screen ring activity. The full-screen intent on the
        //    notification handles the locked case, but we also start it directly
        //    to cover devices where FSI is deferred.
        val activityIntent = Intent(this, AlarmActivity::class.java).apply {
            putExtra(AlarmContract.EXTRA_ID, id)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        try {
            startActivity(activityIntent)
        } catch (e: Exception) {
            Log.w(TAG, "Direct activity start blocked; relying on full-screen intent", e)
        }
    }

    private fun startAudio(sound: String, volume: Double) {
        try {
            val uri = resolveSoundUri(sound)
            mediaPlayer = MediaPlayer().apply {
                setDataSource(this@AlarmForegroundService, uri)
                // USAGE_ALARM => uses the alarm volume stream and bypasses
                // Do-Not-Disturb when the channel is configured as an alarm.
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                val v = volume.coerceIn(0.0, 1.0).toFloat()
                setVolume(v, v)
                setOnPreparedListener { start() }
                prepareAsync()
            }

            // Make sure the alarm stream is audible (some OEMs mute it).
            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val max = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            am.setStreamVolume(
                AudioManager.STREAM_ALARM,
                (max * volume.coerceIn(0.0, 1.0)).toInt().coerceAtLeast(1),
                0,
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start alarm audio", e)
        }
    }

    /**
     * Resolve the configured sound to a playable Uri. Custom sounds are bundled
     * as raw resources named by the [sound] key; "default" falls back to the
     * system default alarm ringtone.
     */
    private fun resolveSoundUri(sound: String): Uri {
        if (sound.isNotEmpty() && sound != "default") {
            val resId = resources.getIdentifier(sound, "raw", packageName)
            if (resId != 0) {
                return Uri.parse("android.resource://$packageName/$resId")
            }
        }
        return RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
    }

    private fun startVibration() {
        val vib = obtainVibrator()
        vibrator = vib
        // Pattern: wait 0, vibrate 800, pause 600, repeat from index 0.
        val pattern = longArrayOf(0, 800, 600)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vib.vibrate(VibrationEffect.createWaveform(pattern, /* repeat = */ 0))
        } else {
            @Suppress("DEPRECATION")
            vib.vibrate(pattern, 0)
        }
    }

    private fun obtainVibrator(): Vibrator {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vm.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    private fun acquireWakeLock() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "alarmapp:ring",
        ).apply {
            // Safety timeout so a bug can never drain the battery forever.
            acquire(10 * 60 * 1000L /* 10 min */)
        }
    }

    private fun stopRinging() {
        try { mediaPlayer?.stop() } catch (_: Exception) {}
        mediaPlayer?.release()
        mediaPlayer = null

        vibrator?.cancel()
        vibrator = null

        if (wakeLock?.isHeld == true) wakeLock?.release()
        wakeLock = null

        currentAlarmId?.let { AlarmSchedulerPlugin.emit(AlarmContract.EVENT_STOPPED, it) }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        // Defensive cleanup in case we're destroyed without an explicit stop.
        stopRinging()
        super.onDestroy()
    }

    // region Notification
    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                AlarmContract.CHANNEL_ID,
                AlarmContract.CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Alarm ringing notifications"
                setBypassDnd(true) // Ring through Do-Not-Disturb.
                enableVibration(false) // We drive vibration ourselves.
                setSound(null, null)   // We drive audio ourselves via MediaPlayer.
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(id: String, label: String): Notification {
        // Full-screen intent: shows the ring UI even over the lock screen.
        val fullScreenIntent = Intent(this, AlarmActivity::class.java).apply {
            putExtra(AlarmContract.EXTRA_ID, id)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        val fullScreenPi = PendingIntent.getActivity(
            this,
            AlarmTime.requestCode(id),
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, AlarmContract.CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle(label.ifEmpty { "Alarm" })
            .setContentText("Tap to complete your mission and stop the alarm")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setCategory(Notification.CATEGORY_ALARM)
            .setOngoing(true) // Cannot be swiped away.
            .setAutoCancel(false)
            .setFullScreenIntent(fullScreenPi, /* highPriority = */ true)
            .setContentIntent(fullScreenPi)
            .build()
    }
    // endregion

    companion object {
        private const val TAG = "AlarmFgService"
    }
}
