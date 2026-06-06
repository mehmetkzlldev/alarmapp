import 'package:audioplayers/audioplayers.dart';

/// Plays the looping alarm sound for the wake-up experience.
///
/// A single shared [AudioPlayer] makes [start]/[stop] idempotent. The asset is a
/// short loopable two-tone beep at `assets/sounds/alarm.wav`.
///
/// On the web a browser only allows audio after a user gesture — callers start
/// it in response to a tap (opening the wake-challenge), so autoplay is allowed.
/// Audio is a best-effort enhancement: failures never block the alarm flow.
class AlarmSound {
  AlarmSound._();
  static final AlarmSound instance = AlarmSound._();

  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  Future<void> start() async {
    if (_playing) return;
    _playing = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('sounds/alarm.wav'));
    } catch (_) {
      _playing = false;
    }
  }

  Future<void> stop() async {
    _playing = false;
    try {
      await _player.stop();
    } catch (_) {}
  }
}
