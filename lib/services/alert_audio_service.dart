import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Dedicated audio service for clinical alerts and manual alarm testing.
/// Plays audible warning and critical alert alarms directly through the device
/// speaker at high priority across Android, Web, and other supported platforms.
class AlertAudioService {
  static AudioPlayer? _player;
  static bool _isPlaying = false;
  static String? _currentPlayingType;

  static bool get isPlaying => _isPlaying;
  static String? get currentPlayingType => _currentPlayingType;

  static AudioPlayer get _instance {
    if (_player == null) {
      _player = AudioPlayer();
      _player!.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _currentPlayingType = null;
      });
      _player!.onPlayerStateChanged.listen((state) {
        _isPlaying = (state == PlayerState.playing);
        if (!_isPlaying) {
          _currentPlayingType = null;
        }
      });
    }
    return _player!;
  }

  /// Plays the Critical Alarm audio ('sounds/critical_alarm.mp3') through speakers
  static Future<bool> playCriticalAlarm({
    double volume = 1.0,
    bool loop = false,
  }) async {
    return _playSound('sounds/critical_alarm.mp3', 'critical',
        volume: volume, loop: loop);
  }

  /// Plays the Warning Alert audio ('sounds/warning_alert.mp3') through speakers
  static Future<bool> playWarningAlert({
    double volume = 1.0,
    bool loop = false,
  }) async {
    return _playSound('sounds/warning_alert.mp3', 'warning',
        volume: volume, loop: loop);
  }

  static Future<bool> _playSound(
    String assetPath,
    String type, {
    double volume = 1.0,
    bool loop = false,
  }) async {
    try {
      final player = _instance;
      await player.stop();

      // Configure audio session context so it routes to speaker loudly
      try {
        await player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: true,
              stayAwake: true,
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.alarm,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: const {},
            ),
          ),
        );
      } catch (e) {
        debugPrint('AlertAudioService setAudioContext warning: $e');
      }

      await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await player.setVolume(volume.clamp(0.0, 1.0));
      await player.play(AssetSource(assetPath));
      _isPlaying = true;
      _currentPlayingType = type;
      debugPrint('AlertAudioService: Playing $assetPath ($type)');
      return true;
    } catch (e) {
      debugPrint('AlertAudioService playSound error: $e');
      _isPlaying = false;
      _currentPlayingType = null;
      return false;
    }
  }

  /// Immediately stops any playing alarm audio
  static Future<void> stopSound() async {
    try {
      if (_player != null) {
        await _player!.stop();
      }
      _isPlaying = false;
      _currentPlayingType = null;
    } catch (e) {
      debugPrint('AlertAudioService stop error: $e');
    }
  }

  @visibleForTesting
  static void resetForTesting() {
    _isPlaying = false;
    _currentPlayingType = null;
  }
}
