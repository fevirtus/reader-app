import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/bookmark_model.dart';
import '../../../core/network/providers.dart';

class BookshelfNotifier extends StateNotifier<AsyncValue<List<BookmarkModel>>> {
  final Ref _ref;

  BookshelfNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final client = _ref.read(apiClientProvider);
      final res = await client.dio.get('/api/user/bookmarks');
      final list = (res.data as List)
          .map((e) => BookmarkModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void syncProgress({
    required String novelId,
    required String chapterId,
    required int chapterNumber,
    Map<String, dynamic>? serverBookmark,
  }) {
    final current = state.valueOrNull ?? const <BookmarkModel>[];

    BookmarkModel? parsedFromServer;
    if (serverBookmark != null) {
      try {
        parsedFromServer = BookmarkModel.fromJson(serverBookmark);
      } catch (_) {
        parsedFromServer = null;
      }
    }

    final index = current.indexWhere((b) => b.novelId == novelId);
    if (index >= 0) {
      final existing = current[index];
      final merged = parsedFromServer ?? BookmarkModel(
        id: existing.id,
        novelId: existing.novelId,
        type: BookmarkType.reading,
        lastChapterId: chapterId,
        lastChapterNumber: chapterNumber,
        readChapters: {
          ...existing.readChapters,
          chapterNumber,
        }.toList()
          ..sort(),
        novel: existing.novel,
      );

      final updated = [...current]..[index] = merged;
      state = AsyncValue.data(updated);
      return;
    }

    if (parsedFromServer != null) {
      state = AsyncValue.data([parsedFromServer, ...current]);
      return;
    }

    // Fallback when API response doesn't include bookmark object.
    final synthetic = BookmarkModel(
      id: 'progress-$novelId',
      novelId: novelId,
      type: BookmarkType.reading,
      lastChapterId: chapterId,
      lastChapterNumber: chapterNumber,
      readChapters: [chapterNumber],
    );
    state = AsyncValue.data([synthetic, ...current]);
  }

  Future<void> toggle(String novelId) async {
    try {
      final client = _ref.read(apiClientProvider);
      final current = state.valueOrNull ?? [];
      final existing = current.where((b) => b.novelId == novelId).toList();
      if (existing.isEmpty) {
        final res = await client.dio.post('/api/user/bookmarks', data: {'novelId': novelId});
        final updated = BookmarkModel.fromJson(res.data as Map<String, dynamic>);
        state = AsyncValue.data([...current, updated]);
      } else {
        await client.dio.delete('/api/user/bookmarks/$novelId');
        state = AsyncValue.data(current.where((b) => b.novelId != novelId).toList());
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool isBookmarked(String novelId) {
    return (state.valueOrNull ?? []).any((b) => b.novelId == novelId);
  }

  Future<void> removeFromShelf(String novelId, BookmarkType type) async {
    try {
      final client = _ref.read(apiClientProvider);
      await client.dio.delete(
        '/api/user/bookmarks/$novelId',
        queryParameters: {'type': type.value},
      );
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.where((b) => b.novelId != novelId || b.type != type).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final bookshelfProvider =
    StateNotifierProvider<BookshelfNotifier, AsyncValue<List<BookmarkModel>>>((ref) {
  return BookshelfNotifier(ref);
});

final readingBookmarksProvider = Provider<List<BookmarkModel>>((ref) {
  final bookmarks = ref.watch(bookshelfProvider).valueOrNull ?? [];
  return bookmarks.where((b) => b.type == BookmarkType.reading).toList();
});

final savedBookmarksProvider = Provider<List<BookmarkModel>>((ref) {
  final bookmarks = ref.watch(bookshelfProvider).valueOrNull ?? [];
  return bookmarks.where((b) => b.type == BookmarkType.bookmarked).toList();
});

final isBookmarkedProvider = Provider.family<bool, String>((ref, novelId) {
  final bookshelf = ref.watch(bookshelfProvider);
  return bookshelf.valueOrNull?.any((b) => b.novelId == novelId) ?? false;
});
