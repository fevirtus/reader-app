import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/models/reading_settings.dart';
import '../../../core/network/providers.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/storage/offline_cache.dart';

// ─── Chapter content ─────────────────────────────────────────────────────────

final chapterProvider =
    FutureProvider.family<ChapterModel, String>((ref, chapterId) async {
  final offlineCache = ref.read(offlineCacheProvider);

  // Try network first, fall back to cache
  try {
    final client = ref.read(apiClientProvider);
    final res = await client.dio.get('/api/chapters/$chapterId');
    final chapter = ChapterModel.fromJson(res.data as Map<String, dynamic>);
    // Cache for offline use (fire and forget)
    unawaited(offlineCache.saveChapter(chapter));
    return chapter;
  } catch (_) {
    final cached = await offlineCache.loadChapter(chapterId);
    if (cached != null) return cached;
    rethrow;
  }
});

// ─── Reading progress ─────────────────────────────────────────────────────────

class ReadingProgress {
  final String novelId;
  final String chapterId;
  final int chapterNumber;
  final double scrollOffset;

  const ReadingProgress({
    required this.novelId,
    required this.chapterId,
    required this.chapterNumber,
    required this.scrollOffset,
  });
}

class ReaderNotifier extends StateNotifier<ReadingProgress?> {
  final Ref _ref;
  String? _novelId;

  ReaderNotifier(this._ref) : super(null);

  void open(String novelId, String chapterId, int chapterNumber) {
    _novelId = novelId;
    state = ReadingProgress(
      novelId: novelId,
      chapterId: chapterId,
      chapterNumber: chapterNumber,
      scrollOffset: 0,
    );
    _persistProgress(chapterId, chapterNumber, 0);
  }
  void updateScroll(double offset) {
    if (state == null) return;
    state = ReadingProgress(
      novelId: state!.novelId,
      chapterId: state!.chapterId,
      chapterNumber: state!.chapterNumber,
      scrollOffset: offset,
    );
    _debounceUpdate(offset);
  }

  Future<void> _persistProgress(
      String chapterId, int chapterNumber, double offset) async {
    final localStore = _ref.read(localStoreProvider);
    await localStore.saveProgress(_novelId!, chapterId, chapterNumber, offset);
    // Also notify server (fire and forget)
    try {
      final client = _ref.read(apiClientProvider);
      await client.dio.post('/api/user/reading-progress', data: {
        'novelId': _novelId,
        'chapterId': chapterId,
        'chapterNumber': chapterNumber,
        'progress': offset,
      });
    } catch (_) {}
  }

  DateTime? _lastUpdate;
  Future<void> _debounceUpdate(double offset) async {
    final now = DateTime.now();
    if (_lastUpdate != null && now.difference(_lastUpdate!).inSeconds < 3) return;
    _lastUpdate = now;
    if (state != null) {
      await _persistProgress(state!.chapterId, state!.chapterNumber, offset);
    }
  }
}

final readerProvider =
    StateNotifierProvider<ReaderNotifier, ReadingProgress?>((ref) {
  return ReaderNotifier(ref);
});

// ─── Reading settings ─────────────────────────────────────────────────────────

class ReadingSettingsNotifier extends StateNotifier<ReadingSettings> {
  final Ref _ref;

  ReadingSettingsNotifier(this._ref) : super(const ReadingSettings()) {
    _load();
  }

  Future<void> _load() async {
    final localStore = _ref.read(localStoreProvider);
    final saved = await localStore.loadReadingSettings();
    if (saved != null) state = saved;
  }

  Future<void> update(ReadingSettings settings) async {
    state = settings;
    final localStore = _ref.read(localStoreProvider);
    await localStore.saveReadingSettings(settings);
  }
}

final readingSettingsProvider =
    StateNotifierProvider<ReadingSettingsNotifier, ReadingSettings>((ref) {
  return ReadingSettingsNotifier(ref);
});
