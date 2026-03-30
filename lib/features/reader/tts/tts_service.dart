import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsStatus { idle, playing, paused }

class TtsState {
  final TtsStatus status;
  final int paragraphIndex;
  final int totalParagraphs;
  final double speed;
  final String language;
  final String? voiceName;

  const TtsState({
    this.status = TtsStatus.idle,
    this.paragraphIndex = 0,
    this.totalParagraphs = 0,
    this.speed = 1.0,
    this.language = 'vi-VN',
    this.voiceName,
  });

  TtsState copyWith({
    TtsStatus? status,
    int? paragraphIndex,
    int? totalParagraphs,
    double? speed,
    String? language,
    String? voiceName,
    bool clearVoiceName = false,
  }) =>
      TtsState(
        status: status ?? this.status,
        paragraphIndex: paragraphIndex ?? this.paragraphIndex,
        totalParagraphs: totalParagraphs ?? this.totalParagraphs,
        speed: speed ?? this.speed,
        language: language ?? this.language,
        voiceName: clearVoiceName ? null : (voiceName ?? this.voiceName),
      );

  bool get isPlaying => status == TtsStatus.playing;
}

class TtsNotifier extends StateNotifier<TtsState> {
  final FlutterTts _tts = FlutterTts();
  List<String> _paragraphs = [];
  bool _initialized = false;
  Future<void>? _initFuture;

  TtsNotifier() : super(const TtsState()) {
    _initFuture = _init();
  }

  Future<void> _init() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSharedInstance(true);

    if (Platform.isIOS) {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }

    if (Platform.isAndroid) {
      await _tts.setAudioAttributesForNavigation();
    }

    await _configureVietnameseVoice();
    await _tts.setSpeechRate(1.0);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      state = state.copyWith(status: TtsStatus.playing);
    });

    _tts.setCompletionHandler(() {
      if (state.status == TtsStatus.playing) {
        _next();
      }
    });

    _tts.setErrorHandler((msg) {
      state = state.copyWith(status: TtsStatus.idle);
    });

    _initialized = true;
  }

  Future<void> _configureVietnameseVoice() async {
    final dynamic voicesRaw = await _tts.getVoices;

    String? selectedName;
    String selectedLanguage = 'vi-VN';

    if (voicesRaw is List) {
      final vietnamese = voicesRaw.whereType<Map>().where((voice) {
        final locale = (voice['locale'] ?? voice['language'] ?? '').toString().toLowerCase();
        return locale.startsWith('vi');
      }).toList();

      if (vietnamese.isNotEmpty) {
        final preferred = vietnamese.firstWhere(
          (voice) =>
              (voice['name']?.toString().toLowerCase().contains('female') ?? false) ||
              (voice['name']?.toString().toLowerCase().contains('natural') ?? false),
          orElse: () => vietnamese.first,
        );
        selectedName = preferred['name']?.toString();
        selectedLanguage =
            (preferred['locale'] ?? preferred['language'] ?? 'vi-VN').toString();
      }
    }

    await _tts.setLanguage(selectedLanguage);
    if (selectedName != null) {
      await _tts.setVoice({'name': selectedName, 'locale': selectedLanguage});
    }
    state = state.copyWith(language: selectedLanguage, voiceName: selectedName);
  }

  /// Start reading from [content] starting at optional [paragraphIndex].
  Future<void> startReading(String content, {int paragraphIndex = 0}) async {
    if (!_initialized) {
      await (_initFuture ?? _init());
    }

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
    await _speak(validIndex);
  }

  Future<void> _speak(int index) async {
    if (index >= _paragraphs.length) {
      state = state.copyWith(status: TtsStatus.idle);
      return;
    }
    await _tts.setSpeechRate(state.speed);
    await _tts.speak(_paragraphs[index]);
  }

  Future<void> _next() async {
    final next = state.paragraphIndex + 1;
    if (next >= state.totalParagraphs) {
      state = state.copyWith(status: TtsStatus.idle, paragraphIndex: 0);
      return;
    }
    state = state.copyWith(paragraphIndex: next);
    await _speak(next);
  }

  Future<void> pause() async {
    await _tts.pause();
    state = state.copyWith(status: TtsStatus.paused);
  }

  Future<void> resume() async {
    if (state.status != TtsStatus.paused) return;
    state = state.copyWith(status: TtsStatus.playing);
    // Use paragraph-level resume for consistent behavior across engines.
    await _speak(state.paragraphIndex);
  }

  Future<void> stop() async {
    await _tts.stop();
    state = state.copyWith(status: TtsStatus.idle, paragraphIndex: 0);
  }

  Future<void> skipForward() async {
    await _tts.stop();
    await _next();
  }

  Future<void> skipBack() async {
    await _tts.stop();
    if (state.totalParagraphs <= 0) return;
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
    super.dispose();
  }
}

final ttsProvider = StateNotifierProvider<TtsNotifier, TtsState>((ref) {
  return TtsNotifier();
});
