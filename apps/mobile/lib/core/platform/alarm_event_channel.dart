// alarm_event_channel.dart
//
// EventChannel that streams alarm lifecycle events FROM native code TO Flutter.
// The most important event is 'alarm_fired', emitted by the native foreground
// service / AlarmActivity when an alarm starts ringing. The ring controller
// listens here and navigates to the full-screen ring route.
//
// Why an EventChannel (not just a MethodChannel callback)?
//   The alarm can fire while the Flutter engine is cold (process was killed).
//   Native code launches a Flutter engine on the ring route, and once Dart is
//   up it subscribes here; native re-emits the pending event so nothing is lost.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A decoded event coming up from the native alarm engine.
@immutable
class AlarmEvent {
  /// Event type string, e.g. 'alarm_fired', 'alarm_snoozed', 'alarm_stopped'.
  final String type;

  /// The alarm id this event refers to.
  final String alarmId;

  /// Optional extra payload (e.g. snooze count). May be empty.
  final Map<String, dynamic> data;

  const AlarmEvent({
    required this.type,
    required this.alarmId,
    this.data = const <String, dynamic>{},
  });

  bool get isFired => type == AlarmEventChannel.eventFired;

  factory AlarmEvent.fromMap(Map<dynamic, dynamic> map) {
    return AlarmEvent(
      type: (map['type'] ?? '') as String,
      alarmId: (map['alarmId'] ?? '') as String,
      data: <String, dynamic>{
        for (final entry in map.entries)
          if (entry.key != 'type' && entry.key != 'alarmId')
            entry.key.toString(): entry.value,
      },
    );
  }

  @override
  String toString() => 'AlarmEvent($type, $alarmId, $data)';
}

/// Wraps EventChannel 'app/alarm/events' and exposes a broadcast stream.
class AlarmEventChannel {
  AlarmEventChannel([EventChannel? channel])
      : _channel = channel ?? const EventChannel('app/alarm/events');

  final EventChannel _channel;

  // --- Event type constants (shared contract with native) --------------------
  static const String eventFired = 'alarm_fired';
  static const String eventSnoozed = 'alarm_snoozed';
  static const String eventStopped = 'alarm_stopped';

  Stream<AlarmEvent>? _stream;

  /// Broadcast stream of alarm events. The native side replays the most recent
  /// pending 'alarm_fired' event on (re)subscription so a cold-started engine
  /// does not miss the alarm that woke it up.
  Stream<AlarmEvent> get events {
    _stream ??= _channel
        .receiveBroadcastStream()
        .map((dynamic raw) => AlarmEvent.fromMap(raw as Map<dynamic, dynamic>))
        .handleError((Object error, StackTrace st) {
      // Don't let a malformed native payload tear down the stream.
      debugPrint('AlarmEventChannel error: $error');
    });
    return _stream!;
  }

  /// Convenience: stream filtered to just `alarm_fired` events.
  Stream<AlarmEvent> get fired => events.where((e) => e.isFired);
}
