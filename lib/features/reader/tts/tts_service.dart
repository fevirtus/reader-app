import 'dart:async';
import '../../../core/audio/playback_exclusion.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/config/app_config.dart';

enum TtsStatus { idle, playing, paused }

const double kTtsBaseSpeechRate = 0.9;

double ttsDisplayMultiplier(double speechRate) =>
    speechRate / kTtsBaseSpeechRate;

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

  Map<String, Object?> toMap() => {
    'text': text,
    'paragraphIndex': paragraphIndex,
    'start': start,
    'end': end,
  };
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
  final bool isBuffering;
  final String? errorMessage;
  final bool backgroundModeEnabled;
  final bool batteryOptimizationIgnored;
  final String? pendingAutoStartChapterId;

  const TtsState({
    this.status = TtsStatus.idle,
    this.paragraphIndex = 0,
    this.totalParagraphs = 0,
    this.activeParagraphIndex = -1,
    this.speed = 0.9,
    this.language = 'vi-VN',
    this.voiceName,
    this.availableVietnameseVoices = const [],
    this.progressStart = -1,
    this.progressEnd = -1,
    this.contentKey,
    this.completedCount = 0,
    this.isBuffering = false,
    this.errorMessage,
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
    bool? isBuffering,
    String? errorMessage,
    bool clearError = false,
    bool? backgroundModeEnabled,
    bool? batteryOptimizationIgnored,
    String? pendingAutoStartChapterId,
    bool clearPendingAutoStartChapterId = false,
  }) => TtsState(
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
    isBuffering: isBuffering ?? this.isBuffering,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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
  TtsNotifier({bool? useNativeAndroid})
    : _nativeAndroid = useNativeAndroid ?? Platform.isAndroid,
      super(const TtsState()) {
    _initFuture = _init();
  }

  static const MethodChannel _backgroundChannel = MethodChannel(
    'reader_app/tts_background',
  );
  static const MethodChannel _mediaChannel = MethodChannel(
    'reader_app/tts_media',
  );
  static const EventChannel _mediaEventsChannel = EventChannel(
    'reader_app/tts_media_events',
  );

  final FlutterTts _tts = FlutterTts();
  List<_TtsSegment> _segments = [];
  bool _initialized = false;
  Future<void>? _initFuture;
  StreamSubscription<dynamic>? _mediaEventsSub;
  int _playbackGeneration = 0;
  int _commandGeneration = 0;
  bool _isInterruptingPlayback = false;
  int _pendingFallbackIndex = -1;
  bool _didStartCurrentFallbackUtterance = false;
  bool _hasPromptedNotificationSettings = false;
  bool _fallbackReady = false;

  final bool _nativeAndroid;
  bool get _useNativeAndroidMediaService => _nativeAndroid;

  Future<void> _init() async {
    if (_useNativeAndroidMediaService) {
      await _initAndroidBridge();
      _initialized = true;
      return;
    }

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

    await _configureVietnameseVoiceWithFlutterTts();
    await _tts.setSpeechRate(kTtsBaseSpeechRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      _didStartCurrentFallbackUtterance = true;
      final index = _pendingFallbackIndex;
      if (index >= 0 && index < _segments.length) {
        final segment = _segments[index];
        state = state.copyWith(
          status: TtsStatus.playing,
          paragraphIndex: index,
          activeParagraphIndex: segment.paragraphIndex,
          progressStart: segment.start,
          progressEnd: segment.end,
        );
      } else {
        state = state.copyWith(status: TtsStatus.playing);
      }
      unawaited(_syncBackgroundMode());
    });

    _tts.setCompletionHandler(() {
      // Fallback playback progression is driven by _playFallbackFromGeneration.
    });

    _tts.setErrorHandler((msg) {
      if (_isInterruptingPlayback) return;
      _pendingFallbackIndex = -1;
      _didStartCurrentFallbackUtterance = false;
      state = state.copyWith(
        status: TtsStatus.idle,
        activeParagraphIndex: -1,
        progressStart: -1,
        progressEnd: -1,
      );
      unawaited(_syncBackgroundMode());
    });

    await _syncBackgroundMode();
    _initialized = true;
  }

  Future<void> _initAndroidBridge() async {
    _mediaEventsSub ??= _mediaEventsChannel.receiveBroadcastStream().listen(
      _handleAndroidMediaEvent,
      onError: (_) {
        state = state.copyWith(
          status: TtsStatus.idle,
          activeParagraphIndex: -1,
          progressStart: -1,
          progressEnd: -1,
        );
      },
    );

    await _mediaChannel.invokeMethod<void>('initialize', {
      'backgroundModeEnabled': state.backgroundModeEnabled,
    });

    final snapshot = await _mediaChannel.invokeMethod<dynamic>('getSnapshot');
    _applyAndroidSnapshot(snapshot);
  }

  Future<void> _ensureAndroidMediaNotificationsEnabled() async {
    if (!_useNativeAndroidMediaService) return;
    if (_hasPromptedNotificationSettings) return;

    final enabled =
        await _mediaChannel.invokeMethod<bool>('areNotificationsEnabled') ??
        true;
    if (enabled) return;

    _hasPromptedNotificationSettings = true;
    await _mediaChannel.invokeMethod<void>('openNotificationSettings');
  }

  Future<void> refreshNativeSnapshot() async {
    if (!_useNativeAndroidMediaService) return;

    if (!_initialized) {
      await (_initFuture ?? _init());
      return;
    }

    try {
      final snapshot = await _mediaChannel.invokeMethod<dynamic>('getSnapshot');
      _applyAndroidSnapshot(snapshot);
    } catch (_) {
      // Ignore snapshot pull errors; event stream updates will continue.
    }
  }

  Future<void> _configureVietnameseVoiceWithFlutterTts() async {
    final dynamic voicesRaw = await _tts.getVoices;

    String? selectedName;
    String selectedLanguage = 'vi-VN';
    final List<TtsVoice> vietnameseVoices = [];

    if (voicesRaw is List) {
      final vietnamese = voicesRaw.whereType<Map>().where((voice) {
        final locale = (voice['locale'] ?? voice['language'] ?? '')
            .toString()
            .toLowerCase();
        return locale.startsWith('vi');
      }).toList();

      for (final voice in vietnamese) {
        final name = voice['name']?.toString();
        final locale = (voice['locale'] ?? voice['language'])?.toString();
        if (name == null || name.isEmpty || locale == null || locale.isEmpty) {
          continue;
        }
        vietnameseVoices.add(TtsVoice(name: name, locale: locale));
      }

      if (vietnamese.isNotEmpty) {
        final preferred = vietnamese.firstWhere(
          (voice) =>
              (voice['name']?.toString().toLowerCase().contains('female') ??
                  false) ||
              (voice['name']?.toString().toLowerCase().contains('natural') ??
                  false),
          orElse: () => vietnamese.first,
        );
        selectedName = preferred['name']?.toString();
        selectedLanguage =
            (preferred['locale'] ?? preferred['language'] ?? 'vi-VN')
                .toString();
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

  Future<void> _ensureFallbackReady() async {
    if (_fallbackReady) return;

    await _tts.awaitSpeakCompletion(true);
    await _tts.setSharedInstance(true);
    await _configureVietnameseVoiceWithFlutterTts();
    await _tts.setSpeechRate(state.speed);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      _didStartCurrentFallbackUtterance = true;
      final index = _pendingFallbackIndex;
      if (index >= 0 && index < _segments.length) {
        final segment = _segments[index];
        state = state.copyWith(
          status: TtsStatus.playing,
          paragraphIndex: index,
          activeParagraphIndex: segment.paragraphIndex,
          progressStart: segment.start,
          progressEnd: segment.end,
        );
      } else {
        state = state.copyWith(status: TtsStatus.playing);
      }
    });

    _tts.setCompletionHandler(() {
      // Fallback playback progression is driven by _playFallbackFromGeneration.
    });

    _tts.setErrorHandler((_) {
      if (_isInterruptingPlayback) return;
      _pendingFallbackIndex = -1;
      _didStartCurrentFallbackUtterance = false;
      state = state.copyWith(
        status: TtsStatus.idle,
        activeParagraphIndex: -1,
        progressStart: -1,
        progressEnd: -1,
      );
    });

    _fallbackReady = true;
  }

  Future<void> _startFallbackReading({
    required int validIndex,
    required _TtsSegment selectedSegment,
    required String? contentKey,
  }) async {
    await _ensureFallbackReady();
    final sessionId = await _interruptFallbackPlayback();

    state = state.copyWith(
      status: TtsStatus.playing,
      paragraphIndex: validIndex,
      totalParagraphs: _segments.length,
      activeParagraphIndex: selectedSegment.paragraphIndex,
      progressStart: selectedSegment.start,
      progressEnd: selectedSegment.end,
      contentKey: contentKey,
    );

    unawaited(_playFallbackFromGeneration(validIndex, sessionId));
  }

  void _handleAndroidMediaEvent(dynamic event) {
    _applyAndroidSnapshot(event);
  }

  void _applyAndroidSnapshot(dynamic snapshot) {
    if (snapshot is! Map) return;

    final data = Map<String, dynamic>.from(
      snapshot.map((key, value) => MapEntry(key.toString(), value)),
    );

    final statusRaw = data['status']?.toString() ?? 'idle';
    final status = switch (statusRaw) {
      'playing' => TtsStatus.playing,
      'paused' => TtsStatus.paused,
      _ => TtsStatus.idle,
    };

    final voicesRaw = data['availableVietnameseVoices'];
    final voices = <TtsVoice>[];
    if (voicesRaw is List) {
      for (final item in voicesRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(
          item.map((key, value) => MapEntry(key.toString(), value)),
        );
        final name = map['name']?.toString();
        final locale = map['locale']?.toString();
        if (name == null || name.isEmpty || locale == null || locale.isEmpty) {
          continue;
        }
        voices.add(TtsVoice(name: name, locale: locale));
      }
    }

    state = state.copyWith(
      status: status,
      paragraphIndex: (data['paragraphIndex'] as num?)?.toInt() ?? 0,
      totalParagraphs: (data['totalParagraphs'] as num?)?.toInt() ?? 0,
      activeParagraphIndex:
          (data['activeParagraphIndex'] as num?)?.toInt() ?? -1,
      progressStart: (data['progressStart'] as num?)?.toInt() ?? -1,
      progressEnd: (data['progressEnd'] as num?)?.toInt() ?? -1,
      contentKey: data['contentKey']?.toString(),
      clearContentKey: data['contentKey'] == null,
      isBuffering: data['isPreparingNextChapter'] == true,
      errorMessage: data['errorMessage']?.toString(),
      clearError: data['errorMessage'] == null,
      completedCount:
          (data['completedCount'] as num?)?.toInt() ?? state.completedCount,
      language: data['language']?.toString() ?? state.language,
      voiceName: data['voiceName']?.toString(),
      availableVietnameseVoices: voices,
      backgroundModeEnabled:
          data['backgroundModeEnabled'] as bool? ?? state.backgroundModeEnabled,
    );
  }

  String _sanitizeForTts(String raw) {
    if (raw.isEmpty) return raw;

    // Keep natural sentence flow while removing symbols that are usually read out noisily.
    final cleaned = raw
        .replaceAll(RegExp(r'["“”]'), ' ')
        .replaceAll(RegExp(r'[_$#^*+=~`|<>\\\[\]{}]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned;
  }

  List<_TtsSegment> _buildSegments(
    String content, {
    String? title,
    bool includeTitle = true,
  }) {
    final segments = <_TtsSegment>[];

    final titleText = title?.trim();
    if (includeTitle && titleText != null && titleText.isNotEmpty) {
      final sanitizedTitle = _sanitizeForTts(titleText);
      if (sanitizedTitle.isNotEmpty) {
        segments.add(
          _TtsSegment(
            text: sanitizedTitle,
            paragraphIndex: -1,
            start: -1,
            end: -1,
          ),
        );
      }
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
        final sanitizedSentence = _sanitizeForTts(sentence);
        if (sanitizedSentence.isEmpty) continue;

        var start = paragraph.indexOf(sentence, cursor);
        if (start < 0) {
          start = cursor.clamp(0, paragraph.length);
        }

        final end = (start + sentence.length).clamp(0, paragraph.length);
        cursor = end;

        segments.add(
          _TtsSegment(
            text: sanitizedSentence,
            paragraphIndex: pIndex,
            start: start,
            end: end,
          ),
        );
      }
    }

    return segments;
  }

  int _resolveStartIndex(
    int paragraphIndex, {
    int? startParagraphIndex,
    int? startCharOffset,
  }) {
    var validIndex = paragraphIndex.clamp(0, _segments.length - 1);

    if (startParagraphIndex != null) {
      final matchIndex = _segments.indexWhere(
        (segment) =>
            segment.paragraphIndex == startParagraphIndex &&
            (startCharOffset == null || segment.start >= startCharOffset),
      );

      if (matchIndex >= 0) {
        validIndex = matchIndex;
      } else {
        final fallbackIndex = _segments.indexWhere(
          (segment) => segment.paragraphIndex >= startParagraphIndex,
        );
        if (fallbackIndex >= 0) {
          validIndex = fallbackIndex;
        }
      }
    }

    return validIndex;
  }

  Future<void> setVoiceByName(String voiceName) async {
    if (_useNativeAndroidMediaService) {
      final selected = state.availableVietnameseVoices.where(
        (voice) => voice.name == voiceName,
      );
      if (selected.isEmpty) return;

      final voice = selected.first;
      await _mediaChannel.invokeMethod<void>('setVoiceByName', {
        'voiceName': voice.name,
        'language': voice.locale,
      });
      state = state.copyWith(language: voice.locale, voiceName: voice.name);
      return;
    }

    final selected = state.availableVietnameseVoices.where(
      (v) => v.name == voiceName,
    );
    if (selected.isEmpty) return;

    final voice = selected.first;
    if (!voice.locale.toLowerCase().startsWith('vi')) return;

    await _tts.setLanguage(voice.locale);
    await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
    state = state.copyWith(language: voice.locale, voiceName: voice.name);
  }

  Future<void> setBackgroundModeEnabled(bool enabled) async {
    state = state.copyWith(backgroundModeEnabled: enabled);
    if (_useNativeAndroidMediaService) {
      await _mediaChannel.invokeMethod<void>('setBackgroundModeEnabled', {
        'enabled': enabled,
      });
      if (enabled) {
        await ensureBatteryOptimizationIgnored();
      }
      return;
    }

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
      final isIgnored =
          await _backgroundChannel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          false;

      state = state.copyWith(batteryOptimizationIgnored: isIgnored);
      if (isIgnored) return;

      await _backgroundChannel.invokeMethod<void>(
        'requestIgnoreBatteryOptimizations',
      );

      final afterRequest =
          await _backgroundChannel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          false;
      state = state.copyWith(batteryOptimizationIgnored: afterRequest);
    } catch (_) {
      // Ignore bridge errors and keep TTS playback functional.
    }
  }

  Future<void> _syncBackgroundMode() async {
    if (_useNativeAndroidMediaService || !Platform.isAndroid) return;

    final shouldKeepAlive =
        state.backgroundModeEnabled && state.status == TtsStatus.playing;
    try {
      await _backgroundChannel.invokeMethod<void>('setWakeLock', {
        'enabled': shouldKeepAlive,
      });
    } catch (_) {
      // Keep playback functional even if native wake lock bridge is unavailable.
    }
  }

  Future<void> startReading(
    String content, {
    int paragraphIndex = 0,
    int? startParagraphIndex,
    int? startCharOffset,
    String? contentKey,
    String? title,
    String? nextChapterId,
    int? chapterNumber,
    String? apiBaseUrl,
    bool includeTitle = true,
  }) async {
    final command = ++_commandGeneration;
    final stopAudioBook = PlaybackExclusion.stopAudioBook;
    if (stopAudioBook != null) await stopAudioBook();
    if (!_initialized) {
      await (_initFuture ?? _init());
    }

    if (!mounted || command != _commandGeneration) return;
    // A direct start request (tap sentence/play button) should win over any
    // queued chapter auto-start from previous navigation/completion events.
    state = state.copyWith(
      clearPendingAutoStartChapterId: true,
      clearError: true,
    );

    _segments = _buildSegments(
      content,
      title: title,
      includeTitle: includeTitle,
    );

    if (_segments.isEmpty) {
      state = state.copyWith(
        status: TtsStatus.idle,
        paragraphIndex: 0,
        totalParagraphs: 0,
        activeParagraphIndex: -1,
        progressStart: -1,
        progressEnd: -1,
        contentKey: contentKey,
      );
      if (!_useNativeAndroidMediaService) {
        await _syncBackgroundMode();
      }
      return;
    }

    final validIndex = _resolveStartIndex(
      paragraphIndex,
      startParagraphIndex: startParagraphIndex,
      startCharOffset: startCharOffset,
    );
    final selectedSegment = _segments[validIndex];

    if (_useNativeAndroidMediaService) {
      await _ensureAndroidMediaNotificationsEnabled();
      if (!mounted || command != _commandGeneration) return;

      state = state.copyWith(
        status: TtsStatus.playing,
        paragraphIndex: validIndex,
        totalParagraphs: _segments.length,
        activeParagraphIndex: selectedSegment.paragraphIndex,
        progressStart: selectedSegment.start,
        progressEnd: selectedSegment.end,
        contentKey: contentKey,
      );

      try {
        await _mediaChannel.invokeMethod<void>('startReading', {
          'content': content,
          'contentKey': contentKey,
          'title': title,
          'nextChapterId': nextChapterId,
          'chapterNumber': chapterNumber,
          'apiBaseUrl': apiBaseUrl ?? AppConfig.baseUrl,
          'startIndex': validIndex,
          'speed': state.speed,
          'language': state.language,
          'voiceName': state.voiceName,
          'backgroundModeEnabled': state.backgroundModeEnabled,
          'includeTitle': includeTitle,
        });
      } on PlatformException {
        if (mounted && command == _commandGeneration) {
          state = state.copyWith(
            status: TtsStatus.idle,
            errorMessage:
                'Không khởi động được giọng đọc. Hãy nhấn phát để thử lại.',
          );
        }
      }
      return;
    }

    await _startFallbackReading(
      validIndex: validIndex,
      selectedSegment: selectedSegment,
      contentKey: contentKey,
    );
  }

  Future<int> _interruptFallbackPlayback() async {
    _playbackGeneration++;
    _pendingFallbackIndex = -1;
    _didStartCurrentFallbackUtterance = false;
    _isInterruptingPlayback = true;

    try {
      await _tts.stop();
      if (Platform.isAndroid) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    } finally {
      _isInterruptingPlayback = false;
    }

    return _playbackGeneration;
  }

  Future<void> _playFallbackFromGeneration(
    int startIndex,
    int generation,
  ) async {
    if (startIndex < 0 || startIndex >= _segments.length) {
      state = state.copyWith(
        status: TtsStatus.idle,
        paragraphIndex: 0,
        activeParagraphIndex: -1,
        progressStart: -1,
        progressEnd: -1,
      );
      await _syncBackgroundMode();
      return;
    }

    for (var index = startIndex; index < _segments.length; index++) {
      if (generation != _playbackGeneration) return;
      if (state.status != TtsStatus.playing) return;

      _pendingFallbackIndex = index;
      _didStartCurrentFallbackUtterance = false;

      state = state.copyWith(
        status: TtsStatus.playing,
        paragraphIndex: index,
        totalParagraphs: _segments.length,
        activeParagraphIndex: -1,
        progressStart: -1,
        progressEnd: -1,
      );
      await _syncBackgroundMode();

      await _tts.setSpeechRate(state.speed);
      final result = await _tts.speak(_segments[index].text);

      if (generation != _playbackGeneration) return;
      if (state.status != TtsStatus.playing) return;

      if (result is int && result != 1) {
        state = state.copyWith(
          status: TtsStatus.idle,
          activeParagraphIndex: -1,
          progressStart: -1,
          progressEnd: -1,
        );
        await _syncBackgroundMode();
        return;
      }

      if (!_didStartCurrentFallbackUtterance) {
        state = state.copyWith(
          status: TtsStatus.idle,
          activeParagraphIndex: -1,
          progressStart: -1,
          progressEnd: -1,
        );
        await _syncBackgroundMode();
        return;
      }
    }

    if (generation != _playbackGeneration) return;

    _pendingFallbackIndex = -1;
    _didStartCurrentFallbackUtterance = false;

    state = state.copyWith(
      status: TtsStatus.idle,
      paragraphIndex: 0,
      activeParagraphIndex: -1,
      progressStart: -1,
      progressEnd: -1,
      completedCount: state.completedCount + 1,
    );
    await _syncBackgroundMode();
  }

  Future<void> pause() async {
    ++_commandGeneration;
    if (_useNativeAndroidMediaService) {
      await _mediaChannel.invokeMethod<void>('pause');
      return;
    }

    if (state.status != TtsStatus.playing) return;

    _playbackGeneration++;
    await _tts.pause();
    state = state.copyWith(status: TtsStatus.paused);
    await _syncBackgroundMode();
  }

  Future<void> _restartFallbackFromIndex(int index) async {
    if (_segments.isEmpty) return;

    final sessionId = await _interruptFallbackPlayback();
    final validIndex = index.clamp(0, _segments.length - 1);

    state = state.copyWith(
      status: TtsStatus.playing,
      paragraphIndex: validIndex,
      totalParagraphs: _segments.length,
      activeParagraphIndex: -1,
      progressStart: -1,
      progressEnd: -1,
    );
    await _syncBackgroundMode();

    unawaited(_playFallbackFromGeneration(validIndex, sessionId));
  }

  Future<void> resume() async {
    final command = ++_commandGeneration;
    final stopAudioBook = PlaybackExclusion.stopAudioBook;
    if (stopAudioBook != null) await stopAudioBook();
    if (!mounted || command != _commandGeneration) return;
    if (_useNativeAndroidMediaService) {
      await _mediaChannel.invokeMethod<void>('resume');
      return;
    }

    if (state.status != TtsStatus.paused) return;
    await _restartFallbackFromIndex(state.paragraphIndex);
  }

  Future<void> stop() async {
    ++_commandGeneration;
    state = state.copyWith(
      clearPendingAutoStartChapterId: true,
      clearError: true,
      isBuffering: false,
    );
    if (_useNativeAndroidMediaService) {
      await _mediaChannel.invokeMethod<void>('stop');
      state = state.copyWith(
        status: TtsStatus.idle,
        paragraphIndex: 0,
        activeParagraphIndex: -1,
        progressStart: -1,
        progressEnd: -1,
        clearContentKey: true,
      );
      return;
    }

    await _interruptFallbackPlayback();
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
    if (_useNativeAndroidMediaService) {
      await _mediaChannel.invokeMethod<void>('skipForward');
      return;
    }

    if (_segments.isEmpty || state.totalParagraphs <= 0) return;

    final next = state.paragraphIndex + 1;
    if (next >= _segments.length) {
      await stop();
      return;
    }

    await _restartFallbackFromIndex(next);
  }

  Future<void> skipBack() async {
    if (_useNativeAndroidMediaService) {
      await _mediaChannel.invokeMethod<void>('skipBack');
      return;
    }

    if (_segments.isEmpty || state.totalParagraphs <= 0) return;

    final prev = (state.paragraphIndex - 1).clamp(0, _segments.length - 1);
    await _restartFallbackFromIndex(prev);
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);

    if (_useNativeAndroidMediaService) {
      await _mediaChannel.invokeMethod<void>('setSpeed', {'speed': speed});
      return;
    }

    await _tts.setSpeechRate(speed);
  }

  @override
  void dispose() {
    _mediaEventsSub?.cancel();
    if (_useNativeAndroidMediaService) {
      unawaited(_mediaChannel.invokeMethod<void>('dispose'));
    } else {
      unawaited(_tts.stop());
    }
    super.dispose();
  }
}

final ttsProvider = StateNotifierProvider<TtsNotifier, TtsState>((ref) {
  return TtsNotifier();
});
