import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/audio/playback_exclusion.dart';
import '../../core/config/app_config.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/providers.dart';
import '../auth/providers/auth_provider.dart';
import '../reader/tts/tts_service.dart';

typedef AudioJson = Map<String, dynamic>;

final audioBookControllerProvider = ChangeNotifierProvider(
  (ref) => AudioBookController(ref),
);

class AudioBookController extends ChangeNotifier {
  AudioBookController(this.ref) {
    PlaybackExclusion.stopAudioBook = stop;
    _states = player.playerStateStream.listen((s) {
      if (_disposed) return;
      if (!loading && s.processingState == ProcessingState.ready) {
        _wantsPlay = s.playing && previewVoiceId == null;
      }
      notifyListeners();
      if (!loading && s.processingState == ProcessingState.completed) {
        _wantsPlay = false;
        previewVoiceId = null;
        notifyListeners();
        unawaited(save());
      }
    });
    _indexes = player.currentIndexStream.listen((index) {
      if (loading || index == null || index >= _queue.length) return;
      final next = _queue[index];
      if (next['assetId'] == chapter?['assetId']) return;
      chapter = Map.of(next);
      _resumePosition = Duration.zero;
      notifyListeners();
      unawaited(save());
    });
    _errors = player.errorStream.listen((e) => _failed(_generation));
    _positions = player.positionStream.listen((position) {
      if (!loading && player.processingState == ProcessingState.ready) {
        _resumePosition = position;
      }
    });
    _network = ref.read(connectivityServiceProvider).onStatusChange.listen((
      online,
    ) {
      if (online && error != null && _wantsPlay && !loading) {
        _retry?.cancel();
        _retry = null;
        unawaited(_resume());
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (player.playing && player.processingState == ProcessingState.ready) {
        unawaited(save());
      }
    });
    ref.listen(authProvider, (previous, next) {
      final before = previous is AuthAuthenticated ? previous.user.id : 'guest';
      final after = next is AuthAuthenticated ? next.user.id : 'guest';
      if (before != after) unawaited(stop());
    });
  }
  final Ref ref;
  final player = AudioPlayer(
    audioLoadConfiguration: const AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        minBufferDuration: Duration(seconds: 15),
        maxBufferDuration: Duration(seconds: 30),
        bufferForPlaybackDuration: Duration(seconds: 1),
        bufferForPlaybackAfterRebufferDuration: Duration(seconds: 3),
        targetBufferBytes: 2 * 1024 * 1024,
      ),
      darwinLoadControl: DarwinLoadControl(
        preferredForwardBufferDuration: Duration(seconds: 30),
      ),
    ),
  );
  String? previewVoiceId;
  double? _speedBeforePreview;
  AudioJson? edition;
  AudioJson? chapter;
  List<AudioJson> _queue = [];
  String? error;
  bool loading = false;
  bool _wantsPlay = false, _disposed = false;
  int _generation = 0, _failures = 0;
  Timer? _retry;
  Duration _resumePosition = Duration.zero;
  bool _syncing = false;
  String _account = 'guest';
  late final StreamSubscription<PlayerState> _states;
  late final StreamSubscription<PlayerException> _errors;
  late final StreamSubscription<int?> _indexes;
  late final StreamSubscription<Duration> _positions;
  late final StreamSubscription<bool> _network;
  late final Timer _timer;
  String get account {
    final a = ref.read(authProvider);
    return a is AuthAuthenticated ? a.user.id : 'guest';
  }

  String key(String uid, String novel) => 'audio-progress:$uid:$novel';
  Future<void> play(
    AudioJson book,
    AudioJson item, {
    Duration? position,
  }) async {
    if (item['assetId'] == null || item['url'] == null) {
      error = 'Chương này đang chờ tạo Audio book';
      notifyListeners();
      return;
    }
    final generation = ++_generation;
    _retry?.cancel();
    _retry = null;
    await save();
    if (generation != _generation || _disposed) return;
    previewVoiceId = null;
    loading = true;
    _wantsPlay = true;
    error = null;
    notifyListeners();
    try {
      await ref.read(ttsProvider.notifier).stop();
      if (generation != _generation) return;
      await player.stop();
      if (generation != _generation) return;
      await _restoreSpeed();
      if (generation != _generation) return;
      _account = account;
      final prefs = await SharedPreferences.getInstance();
      final saved = jsonDecode(
        prefs.getString(key(_account, book['novelId'])) ?? 'null',
      );
      _resumePosition =
          position ??
          (saved is Map && saved['assetId'] == item['assetId']
              ? Duration(
                  milliseconds: ((saved['position'] as num) * 1000).round(),
                )
              : Duration.zero);
      if (generation != _generation) return;
      edition = Map.of(book);
      chapter = Map.of(item);
      final chapters = (book['chapters'] as List)
          .map((c) => Map<String, dynamic>.from(c))
          .toList();
      final start = chapters.indexWhere((c) => c['assetId'] == item['assetId']);
      // Lazy preparation + a bounded native buffer; never persist audio to disk.
      // Stop at the first unavailable chapter rather than skipping story content.
      _queue = start < 0
          ? [item]
          : chapters
                .skip(start)
                .takeWhile((c) => c['assetId'] != null && c['url'] != null)
                .toList();
      await player
          .setAudioSources(
            _queue
                .map(
                  (c) => AudioSource.uri(
                    Uri.parse(AppConfig.baseUrl).resolve(c['url']),
                    tag: MediaItem(
                      id: c['assetId'],
                      album: book['title'],
                      title: 'Chương ${c['number']} · ${c['title'] ?? ''}',
                    ),
                  ),
                )
                .toList(),
            initialIndex: 0,
            initialPosition: _resumePosition,
          )
          .timeout(const Duration(seconds: 30));
      if (generation != _generation) return;
      _failures = 0;
      unawaited(player.play().catchError((Object e) => _failed(generation)));
    } catch (_) {
      _failed(generation);
    } finally {
      if (generation == _generation && !_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> previewVoice(AudioJson voice) async {
    if (voice['previewUrl'] == null) return;
    if (previewVoiceId == voice['id']) {
      await stop();
      return;
    }
    final stopping = stop();
    final generation = _generation;
    await stopping;
    if (generation != _generation || _disposed) return;
    _speedBeforePreview = player.speed;
    previewVoiceId = voice['id'];
    loading = true;
    error = null;
    notifyListeners();
    try {
      await ref.read(ttsProvider.notifier).stop();
      if (generation != _generation || _disposed) return;
      await player
          .setAudioSource(
            AudioSource.uri(
              Uri.parse(AppConfig.baseUrl).resolve(voice['previewUrl']),
              tag: MediaItem(
                id: 'voice-preview:${voice['id']}',
                title: 'Nghe thử · ${voice['name']}',
              ),
            ),
          )
          .timeout(const Duration(seconds: 20));
      if (generation != _generation || _disposed) return;
      await player.setSpeed(1);
      unawaited(player.play().catchError((Object e) => _failed(generation)));
    } catch (_) {
      _failed(generation);
    } finally {
      if (generation == _generation && !_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void _failed(int generation) {
    if (!_disposed && generation == _generation && previewVoiceId != null) {
      previewVoiceId = null;
      error = 'Không phát được đoạn nghe thử. Vui lòng thử lại.';
      notifyListeners();
      return;
    }
    if (_disposed || generation != _generation || !_wantsPlay) return;
    error = 'Kết nối bị gián đoạn. Sẽ tự phát tiếp khi kết nối trở lại.';
    notifyListeners();
    if (_retry?.isActive ?? false) return;
    final seconds = [2, 5, 10, 20, 30][_failures.clamp(0, 4)];
    _failures++;
    _retry = Timer(Duration(seconds: seconds), () {
      _retry = null;
      if (generation == _generation) unawaited(_resume());
    });
  }

  Future<void> _resume() async {
    final book = edition, item = chapter;
    if (!_wantsPlay || loading || book == null || item == null || _disposed) {
      return;
    }
    await play(book, item, position: _resumePosition);
  }

  Future<void> toggle() async {
    if (player.playing || (_wantsPlay && error != null)) {
      _wantsPlay = false;
      _retry?.cancel();
      _retry = null;
      await player.pause();
      await save();
      notifyListeners();
    } else if (error != null ||
        player.processingState == ProcessingState.idle) {
      _wantsPlay = true;
      await _resume();
    } else {
      await ref.read(ttsProvider.notifier).stop();
      _wantsPlay = true;
      unawaited(player.play().catchError((Object e) => _failed(_generation)));
    }
  }

  Future<void> _restoreSpeed() async {
    final speed = _speedBeforePreview;
    _speedBeforePreview = null;
    if (speed != null) await player.setSpeed(speed);
  }

  Future<void> stop() async {
    final generation = ++_generation;
    _wantsPlay = false;
    _retry?.cancel();
    _retry = null;
    await save();
    if (generation != _generation) return;
    await player.stop();
    if (generation != _generation) return;
    await _restoreSpeed();
    if (generation != _generation) return;
    previewVoiceId = null;
    edition = null;
    chapter = null;
    _queue = [];
    loading = false;
    error = null;
    if (!_disposed) notifyListeners();
  }

  Future<void> save() async {
    final book = edition;
    final item = chapter;
    if (book == null ||
        item == null ||
        loading ||
        player.processingState == ProcessingState.idle) {
      return;
    }
    final uid = _account;
    final prefs = await SharedPreferences.getInstance();
    final event = {
      'userId': uid,
      'editionId': book['id'],
      'assetId': item['assetId'],
      'position': _resumePosition.inMilliseconds / 1000,
      'eventId': const Uuid().v4(),
      'occurredAt': DateTime.now().toUtc().toIso8601String(),
    };
    final k = key(uid, book['novelId']);
    await prefs.setString(k, jsonEncode(event));
    if (uid != 'guest') {
      await prefs.setString('$k:pending', jsonEncode(event));
      unawaited(sync(book['novelId'], uid));
    }
  }

  Future<void> sync(String novel, String uid) async {
    if (_syncing || uid == 'guest' || uid != account) return;
    _syncing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final k = key(uid, novel);
      final pending = prefs.getString('$k:pending');
      final dio = ref.read(apiClientProvider).dio;
      if (pending != null) {
        final event = jsonDecode(pending);
        final result = await dio.post(
          '/api/audiobooks/progress/$novel',
          data: event,
        );
        if (result.data['acknowledgedEventId'] == event['eventId'] &&
            prefs.getString('$k:pending') == pending) {
          await prefs.remove('$k:pending');
        }
      }
      if (account != uid) return;
      final result = await dio.get('/api/audiobooks/progress/$novel');
      final remote = result.data['progress'];
      final local = jsonDecode(prefs.getString(k) ?? 'null');
      if (remote != null &&
          (local == null ||
              DateTime.parse(
                remote['occurredAt'],
              ).isAfter(DateTime.parse(local['occurredAt'])))) {
        await prefs.setString(k, jsonEncode(remote));
      }
    } catch (_) {
      /* Retry durable pending progress on the next save/open. */
    } finally {
      _syncing = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _retry?.cancel();
    unawaited(_network.cancel());
    unawaited(_indexes.cancel());
    unawaited(_positions.cancel());
    PlaybackExclusion.stopAudioBook = null;
    _timer.cancel();
    unawaited(_states.cancel());
    unawaited(_errors.cancel());
    unawaited(player.dispose());
    super.dispose();
  }
}
