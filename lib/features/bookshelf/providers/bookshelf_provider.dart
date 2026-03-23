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
}

final bookshelfProvider =
    StateNotifierProvider<BookshelfNotifier, AsyncValue<List<BookmarkModel>>>((ref) {
  return BookshelfNotifier(ref);
});

final isBookmarkedProvider = Provider.family<bool, String>((ref, novelId) {
  final bookshelf = ref.watch(bookshelfProvider);
  return bookshelf.valueOrNull?.any((b) => b.novelId == novelId) ?? false;
});
