package com.alarmapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Default app entry activity. We manually register AlarmSchedulerPlugin so the
 * MethodChannel/EventChannel are wired up regardless of plugin auto-discovery.
 *
 * AlarmActivity (the lock-screen ring surface) is a SEPARATE activity; the
 * plugin is registered there too via the shared engine lifecycle when a cached
 * engine is used.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(AlarmSchedulerPlugin())
    }
}
