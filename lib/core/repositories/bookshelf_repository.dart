import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bookmark_model.dart';
import '../storage/offline_store.dart';
import 'novels_repository.dart';
import '../../features/auth/providers/auth_provider.dart';

class BookshelfRepository {
  BookshelfRepository(this.store, this.owner, this.novels);
  final OfflineStore store;
  final String owner;
  final NovelsRepository novels;

  Future<List<BookmarkModel>> loadCached() async {
    final raw = await store.read(owner, 'bookshelf') as List? ?? [];
    final books = {
      for (final b in raw)
        (b['novelId'] as String): BookmarkModel.fromJson(
          Map<String, dynamic>.from(b),
        ),
    };
    final pending = (await store.entries(owner, 'outbox:')).values.toList()
      ..sort(
        (a, b) =>
            (a['occurredAt'] as String).compareTo(b['occurredAt'] as String),
      );
    for (final op in pending) {
      final id = op['novelId'] as String;
      if (op['kind'] == 'remove') {
        books.remove(id);
        continue;
      }
      final old =
          books[id] ??
          BookmarkModel(
            id: 'local-$id',
            novelId: id,
            novel: await novels.getCachedNovel(id),
          );
      if (op['kind'] == 'progress') {
        books[id] = old.copyWith(
          lastChapterId: op['chapterId'],
          lastChapterNumber: op['chapterNumber'],
          readChapters: {
            ...old.readChapters,
            op['chapterNumber'] as int,
          }.toList()..sort(),
        );
      } else if (op['kind'] == 'markAsRead') {
        books[id] = old.copyWith(markedAsRead: true);
      }
    }
    return books.values.toList();
  }

  Future<void> saveServer(List<dynamic> list) async {
    await store.write(owner, 'bookshelf', list);
  }
}

final bookshelfRepositoryProvider = Provider(
  (ref) => BookshelfRepository(
    ref.watch(offlineStoreProvider),
    ref.watch(currentUserProvider)?.id ?? 'guest',
    ref.watch(novelsRepositoryProvider),
  ),
);
