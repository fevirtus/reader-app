import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/models/reading_settings.dart';
import '../../../core/network/providers.dart';
import '../../../core/repositories/chapters_repository.dart';
import '../../../core/storage/local_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/sync/user_sync.dart';

// ─── Chapter content ─────────────────────────────────────────────────────────

final chapterProvider = FutureProvider.family<ChapterModel, String>((
  ref,
  chapterId,
) async {
  final chaptersRepo = ref.read(chaptersRepositoryProvider);

  // Keep the current reading session stable and never wait for the network
  // when this chapter is already available on the device.
  final local = await chaptersRepo.getCachedChapter(chapterId);
  if (local != null) return local;

  // Fetch only chapters which have never been saved locally.
  try {
    final client = ref.read(apiClientProvider);
    final res = await client.dio.get('/api/chapters/$chapterId');
    final chapter = ChapterModel.fromJson(res.data as Map<String, dynamic>);
    // Cache for offline use (fire and forget) — không hạ cờ nếu chương đã được tải chủ động.
    unawaited(chaptersRepo.cacheViewedChapter(chapter));
    return chapter;
  } catch (_) {
    debugPrint(
      '[READER][CHAPTER][ERROR] Failed to load chapterId=$chapterId from network, trying cache',
    );
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
  String? _owner;

  ReaderNotifier(this._ref) : super(null);

  void open(String novelId, String chapterId, int chapterNumber) {
    _owner = _ref.read(currentUserProvider)?.id;
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
    unawaited(_persistProgress(state!.chapterId, state!.chapterNumber, offset));
  }

  Future<void> _persistProgress(
    String chapterId,
    int chapterNumber,
    double offset,
  ) async {
    final occurredAt = DateTime.now();
    final novelId = _novelId;
    final owner = _owner;
    if (novelId == null || owner != _ref.read(currentUserProvider)?.id) return;
    final localStore = _ref.read(localStoreProvider);
    final sync = _ref.read(userSyncProvider);
    if (owner == null) {
      await localStore.saveProgress(novelId, chapterId, chapterNumber, offset);
    } else {
      await sync.enqueue(owner, {
        'kind': 'progress',
        'novelId': novelId,
        'chapterId': chapterId,
        'chapterNumber': chapterNumber,
        'progress': offset,
      }, occurredAt: occurredAt);
    }
  }
}

final readerProvider = StateNotifierProvider<ReaderNotifier, ReadingProgress?>((
  ref,
) {
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
