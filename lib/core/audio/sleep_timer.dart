import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/reader/tts/tts_service.dart';
import 'playback_exclusion.dart';

final sleepTimerProvider = ChangeNotifierProvider<SleepTimer>((ref) {
  return SleepTimer(
    onExpire: () async {
      // Both commands start immediately, before awaiting platform or storage I/O.
      final tts = ref.read(ttsProvider.notifier);
      tts.clearPendingAutoStartChapter();
      final state = ref.read(ttsProvider);
      await Future.wait([
        if (state.status != TtsStatus.idle || state.isBuffering) tts.pause(),
        if (PlaybackExclusion.pauseAudioBook != null)
          PlaybackExclusion.pauseAudioBook!(),
      ]);
    },
  );
});

/// One monotonic deadline across screens, chapters, and playback engines.
class SleepTimer extends ChangeNotifier {
  SleepTimer({required this.onExpire, bool? nativeAndroid})
    : _nativeAndroid =
          nativeAndroid ?? defaultTargetPlatform == TargetPlatform.android;
  static const channel = MethodChannel('reader_app/sleep_timer');
  final Future<void> Function() onExpire;
  final bool _nativeAndroid;
  final Stopwatch _clock = Stopwatch();
  Duration? _duration;
  DateTime? _deadline;
  Timer? _tick;
  bool _disposed = false;
  String? error;

  Duration? get remaining {
    final duration = _duration;
    if (duration == null) return null;
    final monotonic = duration - _clock.elapsed;
    final wall = _deadline!.difference(DateTime.now());
    // Account for device sleep even on platforms whose stopwatch suspends;
    // a backwards wall-clock adjustment must not extend the original timer.
    final value = wall < monotonic ? wall : monotonic;
    return value.isNegative ? Duration.zero : value;
  }

  Future<void> set(Duration? duration) async {
    if (duration != null && duration <= Duration.zero) {
      throw ArgumentError.value(duration, 'duration', 'Must be positive');
    }
    // Register native TTS fallback first. A failed bridge must not show an armed timer.
    if (_nativeAndroid) {
      await channel.invokeMethod<void>('set', {
        'milliseconds': duration?.inMilliseconds,
      });
    }
    if (_disposed) return;
    _tick?.cancel();
    _duration = duration;
    _deadline = duration == null ? null : DateTime.now().add(duration);
    error = null;
    _clock.reset();
    if (duration == null) {
      _clock.stop();
    } else {
      _clock.start();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (remaining == Duration.zero) {
          unawaited(_expire());
        } else {
          notifyListeners();
        }
      });
    }
    notifyListeners();
  }

  Future<void> _expire() async {
    _tick?.cancel();
    _duration = null;
    _clock.stop();
    notifyListeners();
    try {
      await onExpire();
    } catch (_) {
      if (!_disposed) {
        error = 'Không thể tạm dừng. Vui lòng kiểm tra trình phát.';
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _tick?.cancel();
    _clock.stop();
    // Do not cancel the native deadline if Android keeps TTS alive without the UI.
    super.dispose();
  }
}
