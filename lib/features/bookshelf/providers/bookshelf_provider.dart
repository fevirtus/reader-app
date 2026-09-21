import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/models/bookmark_model.dart';
import '../../../core/network/providers.dart';
import '../../../core/repositories/bookshelf_repository.dart';
import '../../auth/providers/auth_provider.dart';

class BookshelfNotifier extends StateNotifier<AsyncValue<List<BookmarkModel>>> {
  final Ref _ref;

  BookshelfNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadFromCacheThenSync();
  }

  Future<void> _loadFromCacheThenSync() async {
    final repo = _ref.read(bookshelfRepositoryProvider);
    final cached = await repo.loadCached();
    if (cached.isNotEmpty) {
      state = AsyncValue.data(cached);
    } else {
      // Tủ sách gắn với tài khoản — chưa đăng nhập thì chưa có gì để tải, không phải lỗi.
      state = const AsyncValue.data([]);
    }

    if (!_ref.read(isAuthenticatedProvider)) return;

    final online = await _ref.read(connectivityServiceProvider).checkIsOnline();
    if (online) {
      await fetch();
    } else if (cached.isEmpty) {
      state = AsyncValue.error(
        Exception('Không có mạng và chưa có dữ liệu tủ sách đã lưu'),
        StackTrace.current,
      );
    }
  }

  Future<void> fetch() async {
    // Bookmarks gắn với tài khoản — bỏ qua thay vì gọi API và bị 401 khi chưa đăng nhập.
    if (!_ref.read(isAuthenticatedProvider)) return;
    // Giữ dữ liệu cache hiển thị trong lúc gọi mạng — chỉ hiện loading khi chưa có gì.
    final hadData = state.valueOrNull?.isNotEmpty ?? false;
    if (!hadData) state = const AsyncValue.loading();
    try {
      final client = _ref.read(apiClientProvider);
      final res = await client.dio.get('/api/user/bookmarks');
      final list = (res.data as List)
          .map((e) => BookmarkModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
      unawaited(_ref.read(bookshelfRepositoryProvider).replaceAll(list));
    } catch (e, st) {
      if (!hadData) state = AsyncValue.error(e, st);
      // Nếu đã có cache thì giữ nguyên, coi như "chưa cập nhật được, vẫn xem tạm bản cũ".
    }
  }

  void _persistCurrent() {
    final current = state.valueOrNull;
    if (current != null) {
      unawaited(_ref.read(bookshelfRepositoryProvider).replaceAll(current));
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
      final merged = parsedFromServer ??
          existing.copyWith(
            lastChapterId: chapterId,
            lastChapterNumber: chapterNumber,
            readChapters: {
              ...existing.readChapters,
              chapterNumber,
            }.toList()
              ..sort(),
          );

      final updated = [...current]..[index] = merged;
      state = AsyncValue.data(updated);
      _persistCurrent();
      return;
    }

    if (parsedFromServer != null) {
      state = AsyncValue.data([parsedFromServer, ...current]);
      _persistCurrent();
      return;
    }

    // Fallback when API response doesn't include bookmark object.
    final synthetic = BookmarkModel(
      id: 'progress-$novelId',
      novelId: novelId,
      type: BookmarkType.reading,
      shelfStatus: ShelfStatus.reading,
      lastChapterId: chapterId,
      lastChapterNumber: chapterNumber,
      readChapters: [chapterNumber],
    );
    state = AsyncValue.data([synthetic, ...current]);
    _persistCurrent();
  }

  Future<void> markAsRead(String novelId) async {
    try {
      final client = _ref.read(apiClientProvider);
      final res = await client.dio.post('/api/user/bookmarks', data: {
        'action': 'markAsRead',
        'novelId': novelId,
      });
      final data = res.data as Map<String, dynamic>;
      final bookmarkJson = data['bookmark'] as Map<String, dynamic>?;
      final current = state.valueOrNull ?? [];
      if (bookmarkJson != null) {
        final updated = BookmarkModel.fromJson(bookmarkJson);
        final index = current.indexWhere((b) => b.novelId == novelId);
        if (index >= 0) {
          final next = [...current]..[index] = updated;
          state = AsyncValue.data(next);
        } else {
          state = AsyncValue.data([updated, ...current]);
        }
        _persistCurrent();
      } else {
        await fetch();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool isBookmarked(String novelId) {
    return (state.valueOrNull ?? []).any((b) => b.novelId == novelId);
  }

  Future<void> removeFromShelf(String novelId) async {
    try {
      final client = _ref.read(apiClientProvider);
      await client.dio.delete('/api/user/bookmarks/$novelId');
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.where((b) => b.novelId != novelId).toList(),
      );
      _persistCurrent();
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
  return bookmarks.where((b) => b.shelfStatus == ShelfStatus.reading).toList();
});

final completedBookmarksProvider = Provider<List<BookmarkModel>>((ref) {
  final bookmarks = ref.watch(bookshelfProvider).valueOrNull ?? [];
  return bookmarks.where((b) => b.shelfStatus == ShelfStatus.completed).toList();
});

final isBookmarkedProvider = Provider.family<bool, String>((ref, novelId) {
  final bookshelf = ref.watch(bookshelfProvider);
  return bookshelf.valueOrNull?.any((b) => b.novelId == novelId) ?? false;
});
