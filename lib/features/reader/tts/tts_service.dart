import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum TtsStatus { idle, playing, paused }

class TtsState {
  final TtsStatus status;
  final int paragraphIndex;
  final int totalParagraphs;
  final double speed;

  const TtsState({
    this.status = TtsStatus.idle,
    this.paragraphIndex = 0,
    this.totalParagraphs = 0,
    this.speed = 1.0,
  });

  TtsState copyWith({
    TtsStatus? status,
    int? paragraphIndex,
    int? totalParagraphs,
    double? speed,
  }) =>
      TtsState(
        status: status ?? this.status,
        paragraphIndex: paragraphIndex ?? this.paragraphIndex,
        totalParagraphs: totalParagraphs ?? this.totalParagraphs,
        speed: speed ?? this.speed,
      );

  bool get isPlaying => status == TtsStatus.playing;
}

class TtsNotifier extends StateNotifier<TtsState> {
  final FlutterTts _tts = FlutterTts();
  List<String> _paragraphs = [];

  TtsNotifier() : super(const TtsState()) {
    _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(1.0);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      if (state.status == TtsStatus.playing) {
        _next();
      }
    });

    _tts.setErrorHandler((msg) {
      state = state.copyWith(status: TtsStatus.idle);
      WakelockPlus.disable();
    });
  }

  /// Start reading from [content] starting at optional [paragraphIndex].
  Future<void> startReading(String content, {int paragraphIndex = 0}) async {
    _paragraphs = content
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (_paragraphs.isEmpty) return;

    final validIndex = paragraphIndex.clamp(0, _paragraphs.length - 1);
    state = state.copyWith(
      status: TtsStatus.playing,
      paragraphIndex: validIndex,
      totalParagraphs: _paragraphs.length,
    );
    await WakelockPlus.enable();
    await _speak(validIndex);
  }

  Future<void> _speak(int index) async {
    if (index >= _paragraphs.length) {
      state = state.copyWith(status: TtsStatus.idle);
      await WakelockPlus.disable();
      return;
    }
    await _tts.setSpeechRate(state.speed);
    await _tts.speak(_paragraphs[index]);
  }

  Future<void> _next() async {
    final next = state.paragraphIndex + 1;
    if (next >= state.totalParagraphs) {
      state = state.copyWith(status: TtsStatus.idle, paragraphIndex: 0);
      await WakelockPlus.disable();
      return;
    }
    state = state.copyWith(paragraphIndex: next);
    await _speak(next);
  }

  Future<void> pause() async {
    await _tts.pause();
    state = state.copyWith(status: TtsStatus.paused);
    await WakelockPlus.disable();
  }

  Future<void> resume() async {
    if (state.status != TtsStatus.paused) return;
    state = state.copyWith(status: TtsStatus.playing);
    await WakelockPlus.enable();
    await _speak(state.paragraphIndex);
  }

  Future<void> stop() async {
    await _tts.stop();
    state = state.copyWith(status: TtsStatus.idle, paragraphIndex: 0);
    await WakelockPlus.disable();
  }

  Future<void> skipForward() async {
    await _tts.stop();
    await _next();
  }

  Future<void> skipBack() async {
    await _tts.stop();
    final prev = (state.paragraphIndex - 1).clamp(0, state.totalParagraphs - 1);
    state = state.copyWith(paragraphIndex: prev);
    if (state.status == TtsStatus.playing) await _speak(prev);
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    await _tts.setSpeechRate(speed);
  }

  @override
  void dispose() {
    _tts.stop();
    WakelockPlus.disable();
    super.dispose();
  }
}

final ttsProvider = StateNotifierProvider<TtsNotifier, TtsState>((ref) {
  return TtsNotifier();
});
