import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/models/reading_settings.dart';
import '../../../core/network/providers.dart';
import '../../../core/repositories/chapters_repository.dart';
import '../../../core/storage/local_store.dart';
import '../../bookshelf/providers/bookshelf_provider.dart';

// ─── Chapter content ─────────────────────────────────────────────────────────

final chapterProvider =
    FutureProvider.family<ChapterModel, String>((ref, chapterId) async {
  final chaptersRepo = ref.read(chaptersRepositoryProvider);

  // Try network first, fall back to cache/download đã lưu cục bộ
  try {
    final client = ref.read(apiClientProvider);
    final res = await client.dio.get('/api/chapters/$chapterId');
    final chapter = ChapterModel.fromJson(res.data as Map<String, dynamic>);
    // Cache for offline use (fire and forget) — không hạ cờ nếu chương đã được tải chủ động.
    unawaited(chaptersRepo.cacheViewedChapter(chapter));
    return chapter;
  } catch (_) {
    debugPrint('[READER][CHAPTER][ERROR] Failed to load chapterId=$chapterId from network, trying cache');
    final cached = await chaptersRepo.getCachedChapter(chapterId);
    if (cached != null) return cached;
    debugPrint('[READER][CHAPTER][ERROR] No cache for chapterId=$chapterId');
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
  }

  void resetCurrentChapterProgress() {
    if (state == null) return;

    state = ReadingProgress(
      novelId: state!.novelId,
      chapterId: state!.chapterId,
      chapterNumber: state!.chapterNumber,
      scrollOffset: 0,
    );

    // Persist immediately so a freshly opened chapter always resumes at top.
    unawaited(_persistProgress(state!.chapterId, state!.chapterNumber, 0));
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
      final res = await client.dio.post('/api/user/reading-progress', data: {
        'novelId': _novelId,
        'chapterId': chapterId,
        'chapterNumber': chapterNumber,
        'progress': offset,
      });

      final data = res.data;
      Map<String, dynamic>? bookmarkJson;
      if (data is Map<String, dynamic>) {
        final bookmark = data['bookmark'];
        if (bookmark is Map<String, dynamic>) {
          bookmarkJson = bookmark;
        }
      }

      _ref.read(bookshelfProvider.notifier).syncProgress(
            novelId: _novelId!,
            chapterId: chapterId,
            chapterNumber: chapterNumber,
            serverBookmark: bookmarkJson,
          );
    } catch (_) {}
  }

  Timer? _debounceTimer;
  void _debounceUpdate(double offset) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      if (state != null) {
        unawaited(_persistProgress(state!.chapterId, state!.chapterNumber, offset));
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
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

  Future<void> setSentenceTapTtsEnabled(bool enabled) async {
    await update(state.copyWith(enableSentenceTapTts: enabled));
  }
}

final readingSettingsProvider =
    StateNotifierProvider<ReadingSettingsNotifier, ReadingSettings>((ref) {
  return ReadingSettingsNotifier(ref);
});
