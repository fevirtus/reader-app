import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bookmark_model.dart';
import '../models/novel_model.dart';
import '../storage/database/app_database.dart';
import '../storage/database/mappers.dart';

class BookshelfRepository {
  BookshelfRepository(this._db);

  final AppDatabase _db;

  Future<List<BookmarkModel>> loadCached() async {
    final query = _db.select(_db.bookmarks).join([
      leftOuterJoin(_db.novels, _db.novels.id.equalsExp(_db.bookmarks.novelId)),
    ]);
    final rows = await query.get();
    return rows.map((r) {
      final bookmarkRow = r.readTable(_db.bookmarks);
      final novelRow = r.readTableOrNull(_db.novels);
      return bookmarkRow.toModel(novel: novelRow?.toModel());
    }).toList();
  }

  /// Ghi đè toàn bộ tủ sách cục bộ bằng danh sách mới nhất từ server.
  Future<void> replaceAll(List<BookmarkModel> bookmarks) async {
    await _db.transaction(() async {
      final novels = bookmarks.map((b) => b.novel).whereType<NovelModel>().toList();
      if (novels.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAllOnConflictUpdate(_db.novels, novels.map((n) => n.toCompanion()).toList());
        });
      }
      await _db.delete(_db.bookmarks).go();
      if (bookmarks.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.bookmarks, bookmarks.map((b) => b.toCompanion()).toList());
        });
      }
    });
    await _db.touchSync('bookshelf');
  }
}

final bookshelfRepositoryProvider = Provider<BookshelfRepository>((ref) {
  return BookshelfRepository(ref.watch(appDatabaseProvider));
});
