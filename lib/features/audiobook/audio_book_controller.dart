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
import '../../core/network/providers.dart';
import '../auth/providers/auth_provider.dart';
import '../reader/tts/tts_service.dart';
import 'audio_book_store.dart';

final audioBookStoreProvider = Provider(
  (ref) => AudioBookStore(ref.read(apiClientProvider).dio),
);
final audioBookControllerProvider = ChangeNotifierProvider(
  (ref) => AudioBookController(ref),
);

class AudioBookController extends ChangeNotifier {
  AudioBookController(this.ref) {
    PlaybackExclusion.stopAudioBook = stop;
    _states = player.playerStateStream.listen((s) {
      notifyListeners();
      if (s.processingState == ProcessingState.completed) unawaited(_next());
    });
    _errors = player.errorStream.listen((e) {
      error = 'Không phát được audio. Kiểm tra kết nối và thử lại.';
      notifyListeners();
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (player.playing && player.processingState == ProcessingState.ready) {
        unawaited(save());
      }
    });
    ref.listen(authProvider, (previous, next) {
      unawaited(stop());
    });
  }
  final Ref ref;
  final player = AudioPlayer();
  AudioJson? edition;
  AudioJson? chapter;
  String? error;
  bool loading = false;
  int _generation = 0;
  bool _syncing = false;
  String _account = 'guest';
  late final StreamSubscription<PlayerState> _states;
  late final StreamSubscription<PlayerException> _errors;
  late final Timer _timer;
  String get account {
    final a = ref.read(authProvider);
    return a is AuthAuthenticated ? a.user.id : 'guest';
  }

  String key(String uid, String novel) => 'audio-progress:$uid:$novel';
  Future<void> play(AudioJson book, AudioJson item) async {
    if (item['assetId'] == null) {
      error = 'Chương này đang chờ tạo Audio book';
      notifyListeners();
      return;
    }
    final generation = ++_generation;
    await save();
    await ref.read(ttsProvider.notifier).stop();
    loading = true;
    error = null;
    notifyListeners();
    try {
      await player.stop();
      if (generation != _generation) return;
      _account = account;
      final prefs = await SharedPreferences.getInstance();
      final saved = jsonDecode(
        prefs.getString(key(_account, book['novelId'])) ?? 'null',
      );
      final position = saved is Map && saved['assetId'] == item['assetId']
          ? Duration(milliseconds: ((saved['position'] as num) * 1000).round())
          : Duration.zero;
      final file = await ref
          .read(audioBookStoreProvider)
          .audioFile(book['id'], item['assetId']);
      final uri = await file.exists()
          ? file.uri
          : Uri.parse('${AppConfig.baseUrl}${item['url']}');
      if (generation != _generation) return;
      edition = Map.of(book);
      chapter = Map.of(item);
      await player.setAudioSource(
        AudioSource.uri(
          uri,
          tag: MediaItem(
            id: item['assetId'],
            album: book['title'],
            title: 'Chương ${item['number']} · ${item['title'] ?? ''}',
          ),
        ),
        initialPosition: position,
      );
      if (generation != _generation) return;
      unawaited(
        player.play().catchError((Object e) {
          error = 'Không phát được audio';
          notifyListeners();
        }),
      );
    } catch (_) {
      if (generation == _generation) {
        error = 'Không tải được audio. Bản đã tải vẫn có thể nghe ngoại tuyến.';
      }
    } finally {
      if (generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _next() async {
    await save();
    final book = edition;
    final current = chapter;
    if (book == null || current == null) return;
    final list = (book['chapters'] as List).cast<Map>();
    final i = list.indexWhere((c) => c['id'] == current['id']);
    if (i >= 0 && i + 1 < list.length) {
      await play(book, Map<String, dynamic>.from(list[i + 1]));
    }
  }

  Future<void> toggle() async {
    if (player.playing) {
      await player.pause();
      await save();
    } else {
      await ref.read(ttsProvider.notifier).stop();
      unawaited(player.play());
    }
  }

  Future<void> stop() async {
    ++_generation;
    await save();
    await player.stop();
    edition = null;
    chapter = null;
    loading = false;
    notifyListeners();
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
      'position': player.position.inMilliseconds / 1000,
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
    PlaybackExclusion.stopAudioBook = null;
    _timer.cancel();
    unawaited(_states.cancel());
    unawaited(_errors.cancel());
    unawaited(player.dispose());
    super.dispose();
  }
}
