import 'package:dio/dio.dart';
import '../../../core/sync/user_sync.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/models/bookmark_model.dart';
import '../../../core/network/providers.dart';
import '../../../core/repositories/bookshelf_repository.dart';
import '../../auth/providers/auth_provider.dart';

class BookshelfNotifier extends StateNotifier<AsyncValue<List<BookmarkModel>>> {
  BookshelfNotifier(this._ref, this.owner, this.repo)
    : super(const AsyncValue.loading()) {
    unawaited(_load());
  }
  final Ref _ref;
  final String? owner;
  final BookshelfRepository repo;
  int _generation = 0;

  Future<void> _load() async {
    await reloadCached();
    await fetch();
  }

  Future<void> reloadCached() async {
    final version = ++_generation;
    final list = await repo.loadCached();
    if (mounted && version == _generation) state = AsyncValue.data(list);
  }

  Future<void> fetch() async {
    if (_ref.read(userSyncProvider).isBusy) return;
    if (owner == null || _ref.read(currentUserProvider)?.id != owner) return;
    final online = await _ref.read(connectivityServiceProvider).checkIsOnline();
    if (!online || !mounted) return;
    final token = await _ref.read(secureStoreProvider).getAccessToken();
    if (token == null || !mounted) return;
    try {
      final revision = _ref.read(syncRevisionProvider);
      final res = await _ref
          .read(apiClientProvider)
          .dio
          .get(
            '/api/user/bookmarks',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
      if (!mounted ||
          _ref.read(currentUserProvider)?.id != owner ||
          revision != _ref.read(syncRevisionProvider) || _ref.read(userSyncProvider).isBusy) {
        return;
      }
      await repo.saveServer(res.data as List);
      await reloadCached(); // Overlay unacknowledged local operations after every GET.
    } catch (_) {
      // The durable cache remains visible during outages.
    }
  }

  Future<void> markAsRead(String novelId) async {
    if (owner == null) return;
    await _ref.read(userSyncProvider).enqueue(owner!, {
      'kind': 'markAsRead',
      'novelId': novelId,
    });
    await reloadCached();
  }

  Future<void> removeFromShelf(String novelId) async {
    if (owner == null) return;
    await _ref.read(userSyncProvider).enqueue(owner!, {
      'kind': 'remove',
      'novelId': novelId,
    });
    await reloadCached();
  }

  bool isBookmarked(String novelId) =>
      (state.valueOrNull ?? []).any((b) => b.novelId == novelId);
}

final bookshelfProvider =
    StateNotifierProvider<BookshelfNotifier, AsyncValue<List<BookmarkModel>>>((
      ref,
    ) {
      final notifier = BookshelfNotifier(
        ref,
        ref.watch(currentUserProvider)?.id,
        ref.watch(bookshelfRepositoryProvider),
      );
      ref.listen(syncRevisionProvider, (_, next) {
        unawaited(notifier.reloadCached());
      });
      return notifier;
    });

final readingBookmarksProvider = Provider<List<BookmarkModel>>((ref) {
  final bookmarks = ref.watch(bookshelfProvider).valueOrNull ?? [];
  return bookmarks.where((b) => b.shelfStatus == ShelfStatus.reading).toList();
});

final completedBookmarksProvider = Provider<List<BookmarkModel>>((ref) {
  final bookmarks = ref.watch(bookshelfProvider).valueOrNull ?? [];
  return bookmarks
      .where((b) => b.shelfStatus == ShelfStatus.completed)
      .toList();
});

final isBookmarkedProvider = Provider.family<bool, String>((ref, novelId) {
  final bookshelf = ref.watch(bookshelfProvider);
  return bookshelf.valueOrNull?.any((b) => b.novelId == novelId) ?? false;
});
