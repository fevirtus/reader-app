import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsStatus { idle, playing, paused }

const double kTtsBaseSpeechRate = 0.45;

double ttsDisplayMultiplier(double speechRate) => speechRate / kTtsBaseSpeechRate;

String formatTtsSpeedLabel(double speechRate) {
  final multiplier = ttsDisplayMultiplier(speechRate);
  final rounded = multiplier.roundToDouble();
  if ((multiplier - rounded).abs() < 0.05) {
    return '${rounded.toInt()}x';
  }
  return '${multiplier.toStringAsFixed(1)}x';
}

class _TtsSegment {
  const _TtsSegment({
    required this.text,
    required this.paragraphIndex,
    required this.start,
    required this.end,
  });

  final String text;
  final int paragraphIndex;
  final int start;
  final int end;
}

class TtsVoice {
  const TtsVoice({required this.name, required this.locale});

  final String name;
  final String locale;

  String get displayName => '$name ($locale)';
}

class TtsState {
  final TtsStatus status;
  final int paragraphIndex; // current spoken segment index
  final int totalParagraphs; // total spoken segments
  final int activeParagraphIndex; // paragraph index in chapter content
  final double speed;
  final String language;
  final String? voiceName;
  final List<TtsVoice> availableVietnameseVoices;
  final int progressStart;
  final int progressEnd;
  final String? contentKey;
  final int completedCount;
  final bool backgroundModeEnabled;
  final bool batteryOptimizationIgnored;
  final String? pendingAutoStartChapterId;

  const TtsState({
    this.status = TtsStatus.idle,
    this.paragraphIndex = 0,
    this.totalParagraphs = 0,
    this.activeParagraphIndex = -1,
    this.speed = 0.45,
    this.language = 'vi-VN',
    this.voiceName,
    this.availableVietnameseVoices = const [],
    this.progressStart = -1,
    this.progressEnd = -1,
    this.contentKey,
    this.completedCount = 0,
    this.backgroundModeEnabled = true,
    this.batteryOptimizationIgnored = false,
    this.pendingAutoStartChapterId,
  });

  TtsState copyWith({
    TtsStatus? status,
    int? paragraphIndex,
    int? totalParagraphs,
    int? activeParagraphIndex,
    double? speed,
    String? language,
    String? voiceName,
    List<TtsVoice>? availableVietnameseVoices,
    int? progressStart,
    int? progressEnd,
    String? contentKey,
    bool clearContentKey = false,
    bool clearVoiceName = false,
    int? completedCount,
    bool? backgroundModeEnabled,
    bool? batteryOptimizationIgnored,
    String? pendingAutoStartChapterId,
    bool clearPendingAutoStartChapterId = false,
  }) =>
      TtsState(
        status: status ?? this.status,
        paragraphIndex: paragraphIndex ?? this.paragraphIndex,
        totalParagraphs: totalParagraphs ?? this.totalParagraphs,
        activeParagraphIndex: activeParagraphIndex ?? this.activeParagraphIndex,
        speed: speed ?? this.speed,
        language: language ?? this.language,
        voiceName: clearVoiceName ? null : (voiceName ?? this.voiceName),
        availableVietnameseVoices:
            availableVietnameseVoices ?? this.availableVietnameseVoices,
        progressStart: progressStart ?? this.progressStart,
        progressEnd: progressEnd ?? this.progressEnd,
        contentKey: clearContentKey ? null : (contentKey ?? this.contentKey),
        completedCount: completedCount ?? this.completedCount,
        backgroundModeEnabled: backgroundModeEnabled ?? this.backgroundModeEnabled,
        batteryOptimizationIgnored:
            batteryOptimizationIgnored ?? this.batteryOptimizationIgnored,
        pendingAutoStartChapterId: clearPendingAutoStartChapterId
          ? null
          : (pendingAutoStartChapterId ?? this.pendingAutoStartChapterId),
      );

  bool get isPlaying => status == TtsStatus.playing;
}

class TtsNotifier extends StateNotifier<TtsState> {
  final FlutterTts _tts = FlutterTts();
  static const MethodChannel _backgroundChannel = MethodChannel('reader_app/tts_background');
  List<_TtsSegment> _segments = [];
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
    await _tts.setSpeechRate(kTtsBaseSpeechRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      state = state.copyWith(
        status: TtsStatus.playing,
      );
      unawaited(_syncBackgroundMode());
    });

    _tts.setCompletionHandler(() {
      if (state.status == TtsStatus.playing) {
        _next();
      }
    });

    _tts.setErrorHandler((msg) {
      state = state.copyWith(status: TtsStatus.idle);
      unawaited(_syncBackgroundMode());
    });

    await _syncBackgroundMode();

    _initialized = true;
  }

  Future<void> _configureVietnameseVoice() async {
    final dynamic voicesRaw = await _tts.getVoices;

    String? selectedName;
    String selectedLanguage = 'vi-VN';
    final List<TtsVoice> vietnameseVoices = [];

    if (voicesRaw is List) {
      final vietnamese = voicesRaw.whereType<Map>().where((voice) {
        final locale = (voice['locale'] ?? voice['language'] ?? '').toString().toLowerCase();
        return locale.startsWith('vi');
      }).toList();

      for (final voice in vietnamese) {
        final name = voice['name']?.toString();
        final locale = (voice['locale'] ?? voice['language'])?.toString();
        if (name == null || name.isEmpty || locale == null || locale.isEmpty) continue;
        vietnameseVoices.add(TtsVoice(name: name, locale: locale));
      }

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
    state = state.copyWith(
      language: selectedLanguage,
      voiceName: selectedName,
      availableVietnameseVoices: vietnameseVoices,
    );
  }

  Future<void> setVoiceByName(String voiceName) async {
    final selected = state.availableVietnameseVoices.where((v) => v.name == voiceName);
    if (selected.isEmpty) return;

    final voice = selected.first;
    if (!voice.locale.toLowerCase().startsWith('vi')) return;

    await _tts.setLanguage(voice.locale);
    await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
    state = state.copyWith(language: voice.locale, voiceName: voice.name);
  }

  Future<void> setBackgroundModeEnabled(bool enabled) async {
    state = state.copyWith(backgroundModeEnabled: enabled);
    await _syncBackgroundMode();
    if (enabled) {
      await ensureBatteryOptimizationIgnored();
    }
  }

  void scheduleAutoStartForChapter(String chapterId) {
    state = state.copyWith(pendingAutoStartChapterId: chapterId);
  }

  void clearPendingAutoStartChapter() {
    state = state.copyWith(clearPendingAutoStartChapterId: true);
  }

  Future<void> ensureBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return;
    try {
      final isIgnored = await _backgroundChannel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          false;

      state = state.copyWith(batteryOptimizationIgnored: isIgnored);
      if (isIgnored) return;

      await _backgroundChannel.invokeMethod<void>('requestIgnoreBatteryOptimizations');

      final afterRequest = await _backgroundChannel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          false;
      state = state.copyWith(batteryOptimizationIgnored: afterRequest);
    } catch (_) {
      // Ignore bridge errors and keep TTS playback functional.
    }
  }

  Future<void> _syncBackgroundMode() async {
    if (!Platform.isAndroid) return;

    final shouldKeepAlive =
        state.backgroundModeEnabled && state.status == TtsStatus.playing;
    try {
      await _backgroundChannel
          .invokeMethod<void>('setWakeLock', {'enabled': shouldKeepAlive});
    } catch (_) {
      // Keep playback functional even if native wake lock bridge is unavailable.
    }
  }

  /// Start reading from [content] starting at optional [paragraphIndex].
  Future<void> startReading(
    String content, {
    int paragraphIndex = 0,
    int? startParagraphIndex,
    String? contentKey,
    String? title,
    bool includeTitle = true,
  }) async {
    if (!_initialized) {
      await (_initFuture ?? _init());
    }

    final segments = <_TtsSegment>[];

    final titleText = title?.trim();
    if (includeTitle && titleText != null && titleText.isNotEmpty) {
      segments.add(_TtsSegment(text: titleText, paragraphIndex: -1, start: -1, end: -1));
    }

    final paragraphs = content
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    for (var pIndex = 0; pIndex < paragraphs.length; pIndex++) {
      final paragraph = paragraphs[pIndex];
      final sentenceMatches = RegExp(r'[^.!?…]+[.!?…]*').allMatches(paragraph);
      var cursor = 0;

      for (final match in sentenceMatches) {
        final sentence = match.group(0)?.trim() ?? '';
        if (sentence.isEmpty) continue;
        var start = paragraph.indexOf(sentence, cursor);
        if (start < 0) start = cursor.clamp(0, paragraph.length);
        final end = (start + sentence.length).clamp(0, paragraph.length);
        cursor = end;

        segments.add(
          _TtsSegment(
            text: sentence,
            paragraphIndex: pIndex,
            start: start,
            end: end,
          ),
        );
      }
    }

    _segments = segments;
    if (_segments.isEmpty) return;

    var validIndex = paragraphIndex.clamp(0, _segments.length - 1);
    if (startParagraphIndex != null) {
      final startFromVisible = _segments.indexWhere(
        (segment) => segment.paragraphIndex >= startParagraphIndex,
      );
      if (startFromVisible >= 0) {
        validIndex = startFromVisible;
      }
    }

    final selectedSegment = _segments[validIndex];
    state = state.copyWith(
      status: TtsStatus.playing,
      paragraphIndex: validIndex,
      totalParagraphs: _segments.length,
      activeParagraphIndex: selectedSegment.paragraphIndex,
      progressStart: selectedSegment.start,
      progressEnd: selectedSegment.end,
      contentKey: contentKey,
    );
    await _syncBackgroundMode();
    await _speak(validIndex);
  }

  Future<void> _speak(int index) async {
    if (index >= _segments.length) {
      state = state.copyWith(
        status: TtsStatus.idle,
        activeParagraphIndex: -1,
        progressStart: -1,
        progressEnd: -1,
      );
      await _syncBackgroundMode();
      return;
    }

    final segment = _segments[index];
    state = state.copyWith(
      paragraphIndex: index,
      activeParagraphIndex: segment.paragraphIndex,
      progressStart: segment.start,
      progressEnd: segment.end,
    );

    await _tts.setSpeechRate(state.speed);
    await _tts.speak(segment.text);
  }

  Future<void> _next() async {
    final next = state.paragraphIndex + 1;
    if (next >= state.totalParagraphs) {
      state = state.copyWith(
        status: TtsStatus.idle,
        paragraphIndex: 0,
        activeParagraphIndex: -1,
        progressStart: -1,
        progressEnd: -1,
        completedCount: state.completedCount + 1,
      );
      await _syncBackgroundMode();
      return;
    }
    state = state.copyWith(
      paragraphIndex: next,
      activeParagraphIndex: _segments[next].paragraphIndex,
      progressStart: _segments[next].start,
      progressEnd: _segments[next].end,
    );
    await _speak(next);
  }

  Future<void> pause() async {
    await _tts.pause();
    state = state.copyWith(status: TtsStatus.paused);
    await _syncBackgroundMode();
  }

  Future<void> resume() async {
    if (state.status != TtsStatus.paused) return;
    state = state.copyWith(status: TtsStatus.playing);
    await _syncBackgroundMode();
    // Use paragraph-level resume for consistent behavior across engines.
    await _speak(state.paragraphIndex);
  }

  Future<void> stop() async {
    await _tts.stop();
    state = state.copyWith(
      status: TtsStatus.idle,
      paragraphIndex: 0,
      activeParagraphIndex: -1,
      progressStart: -1,
      progressEnd: -1,
      clearContentKey: true,
    );
    await _syncBackgroundMode();
  }

  Future<void> skipForward() async {
    await _tts.stop();
    await _next();
  }

  Future<void> skipBack() async {
    await _tts.stop();
    if (state.totalParagraphs <= 0) return;
    final prev = (state.paragraphIndex - 1).clamp(0, state.totalParagraphs - 1);
    state = state.copyWith(
      paragraphIndex: prev,
      activeParagraphIndex: _segments[prev].paragraphIndex,
      progressStart: _segments[prev].start,
      progressEnd: _segments[prev].end,
    );
    if (state.status == TtsStatus.playing) await _speak(prev);
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    await _tts.setSpeechRate(speed);
  }

  @override
  void dispose() {
    unawaited(_backgroundChannel.invokeMethod<void>('setWakeLock', {'enabled': false}));
    _tts.stop();
    super.dispose();
  }
}

final ttsProvider = StateNotifierProvider<TtsNotifier, TtsState>((ref) {
  return TtsNotifier();
});
