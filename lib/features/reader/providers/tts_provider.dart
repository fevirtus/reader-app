import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsStatus { idle, playing, paused, stopped }

class TtsState {
  final TtsStatus status;
  final int currentSentenceIndex;
  final List<String> sentences;
  final double speechRate;
  final double volume;
  final double pitch;
  final String? currentLanguage;

  const TtsState({
    this.status = TtsStatus.idle,
    this.currentSentenceIndex = 0,
    this.sentences = const [],
    this.speechRate = 0.5,
    this.volume = 1.0,
    this.pitch = 1.0,
    this.currentLanguage,
  });

  TtsState copyWith({
    TtsStatus? status,
    int? currentSentenceIndex,
    List<String>? sentences,
    double? speechRate,
    double? volume,
    double? pitch,
    String? currentLanguage,
  }) {
    return TtsState(
      status: status ?? this.status,
      currentSentenceIndex: currentSentenceIndex ?? this.currentSentenceIndex,
      sentences: sentences ?? this.sentences,
      speechRate: speechRate ?? this.speechRate,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
      currentLanguage: currentLanguage ?? this.currentLanguage,
    );
  }
}

class TtsNotifier extends Notifier<TtsState> {
  late FlutterTts _tts;

  @override
  TtsState build() {
    _tts = FlutterTts();
    _initTts();
    ref.onDispose(() async {
      await _tts.stop();
    });
    return const TtsState();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(state.speechRate);
    await _tts.setVolume(state.volume);
    await _tts.setPitch(state.pitch);
    // Do NOT use awaitSpeakCompletion(true) — it blocks the Dart↔native channel
    // between sentences, causing Android TTS service to disconnect.
    await _tts.awaitSpeakCompletion(false);

    _tts.setCompletionHandler(_onSentenceComplete);

    _tts.setCancelHandler(() {
      if (state.status == TtsStatus.playing) {
        state = state.copyWith(status: TtsStatus.stopped);
      }
    });

    _tts.setErrorHandler((msg) {
      state = state.copyWith(status: TtsStatus.stopped);
    });
  }

  void _onSentenceComplete() {
    if (state.status != TtsStatus.playing) return;
    final nextIndex = state.currentSentenceIndex + 1;
    if (nextIndex < state.sentences.length) {
      state = state.copyWith(currentSentenceIndex: nextIndex);
      _speakCurrent();
    } else {
      state = state.copyWith(
          status: TtsStatus.stopped, currentSentenceIndex: 0);
    }
  }

  Future<void> _speakCurrent() async {
    if (state.sentences.isEmpty) return;
    if (state.status != TtsStatus.playing) return;
    final sentence = state.sentences[state.currentSentenceIndex];
    await _tts.speak(sentence);
  }

  Future<void> play(List<String> sentences) async {
    await _tts.stop();
    state = state.copyWith(
      sentences: sentences,
      currentSentenceIndex: 0,
      status: TtsStatus.playing,
    );
    await _speakCurrent();
  }

  Future<void> pause() async {
    state = state.copyWith(status: TtsStatus.paused);
    await _tts.pause();
  }

  Future<void> resume() async {
    state = state.copyWith(status: TtsStatus.playing);
    await _speakCurrent();
  }

  Future<void> stop() async {
    state = state.copyWith(status: TtsStatus.stopped, currentSentenceIndex: 0);
    await _tts.stop();
  }

  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
    state = state.copyWith(speechRate: rate);
  }
}

final ttsProvider = NotifierProvider<TtsNotifier, TtsState>(TtsNotifier.new);
