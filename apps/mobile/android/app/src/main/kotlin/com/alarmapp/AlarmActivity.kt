package com.alarmapp

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * The activity shown when an alarm fires. It is launched by the foreground
 * service's full-screen intent and is configured to appear OVER the lock
 * screen and turn the screen on, so the user sees the ring UI immediately even
 * when the phone is locked in their pocket.
 *
 * It hosts a Flutter engine and immediately routes it to the ring route
 * (/alarm-ring) carrying the alarm id, so the Dart AlarmRingScreen takes over.
 *
 * Why a dedicated FlutterActivity (not the normal MainActivity)?
 *   The alarm must be able to launch with the app process dead. A separate
 *   activity declared with showWhenLocked/turnScreenOn in the manifest is the
 *   reliable, OEM-tested path. We use a cached engine when available so the
 *   ring UI appears instantly.
 */
class AlarmActivity : FlutterActivity() {

    private var alarmId: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Configure lock-screen behavior BEFORE super.onCreate so the window is
        // created with the right flags.
        showOverLockScreen()
        super.onCreate(savedInstanceState)
        alarmId = intent.getStringExtra(AlarmContract.EXTRA_ID)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // A second alarm (or re-fire) while this activity is alive.
        intent.getStringExtra(AlarmContract.EXTRA_ID)?.let {
            alarmId = it
            routeToRing(it)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // CRITICAL: register the alarm plugin on THIS (ring) engine too. Without
        // it the 'app/alarm' MethodChannel has no handler here, so the ring
        // screen's stop()/snooze() calls are silently dropped and the alarm
        // never stops after the missions are completed.
        flutterEngine.plugins.add(AlarmSchedulerPlugin())
        // Once Dart is ready, push the ring route + alarm id over a lightweight
        // navigation channel. The Dart side also receives 'alarm_fired' via the
        // EventChannel; this is a belt-and-suspenders direct route push so the
        // UI lands on the ring screen even on the very first frame.
        alarmId?.let { routeToRing(it) }
    }

    private fun routeToRing(id: String) {
        val engine = flutterEngine ?: return
        MethodChannel(engine.dartExecutor.binaryMessenger, NAV_CHANNEL)
            .invokeMethod(
                "navigate",
                mapOf("route" to AlarmContract.RING_ROUTE, AlarmContract.EXTRA_ID to id),
            )
    }

    /**
     * Make the activity visible over the keyguard and wake the screen.
     * Uses the modern setShowWhenLocked/setTurnScreenOn APIs on O_MR1+ and the
     * legacy window flags on older devices.
     */
    private fun showOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            // Ask to dismiss the keyguard (best-effort; secure keyguards stay
            // until the user authenticates, but the ring UI still shows on top).
            km.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD,
            )
        }
        // Keep the screen on while the alarm UI is shown.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    /**
     * Reuse a warm cached engine if the app pre-warmed one (instant ring UI).
     * Returning a cache id makes FlutterActivity attach to that engine instead
     * of spinning up a fresh one.
     */
    override fun getCachedEngineId(): String? =
        if (FlutterEngineCache.getInstance().contains(ENGINE_ID)) ENGINE_ID else null

    companion object {
        // Must match the cache id used when the app pre-warms its engine.
        const val ENGINE_ID = "alarm_engine"
        // Lightweight nav channel name (separate from 'app/alarm').
        const val NAV_CHANNEL = "app/alarm/nav"
    }
}
