import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/novel_model.dart';
import '../storage/database/app_database.dart';
import '../storage/database/mappers.dart';

/// Nguồn dữ liệu cục bộ (offline-first) cho novel metadata và các mục ở Trang chủ.
/// UI đọc qua [watchHomeFeed]/[watchNovel] (phản ứng theo DB); việc gọi API chỉ
/// có nhiệm vụ làm mới DB thông qua [saveHomeFeed]/[saveNovelDetail].
class NovelsRepository {
  NovelsRepository(this._db);

  final AppDatabase _db;

  /// Upsert truyện vào DB — giữ lại genres/series/latestChapter đã biết trước đó
  /// nếu nguồn dữ liệu mới không có (vd: API chi tiết truyện không trả về
  /// `latestChapter`, không được phép xoá mất giá trị Home feed đã lưu).
  Future<void> upsertNovels(Iterable<NovelModel> novels) async {
    final list = novels.toList();
    if (list.isEmpty) return;
    await _db.transaction(() async {
      for (final novel in list) {
        final existing = await (_db.select(_db.novels)..where((t) => t.id.equals(novel.id)))
            .getSingleOrNull();
        var companion = novel.toCompanion();
        if (existing != null) {
          companion = companion.copyWith(
            genresJson: novel.genres.isEmpty ? Value(existing.genresJson) : companion.genresJson,
            seriesJson: novel.series == null ? Value(existing.seriesJson) : companion.seriesJson,
            latestChapterJson:
                novel.latestChapter == null ? Value(existing.latestChapterJson) : companion.latestChapterJson,
          );
        }
        await _db.into(_db.novels).insertOnConflictUpdate(companion);
      }
    });
  }

  /// Lưu danh sách + thứ tự truyện cho một mục Trang chủ (vd: "hot", "latest").
  Future<void> saveHomeFeed(String section, List<NovelModel> novels) async {
    await _db.transaction(() async {
      await upsertNovels(novels);
      await (_db.delete(_db.homeFeedItems)..where((t) => t.section.equals(section))).go();
      if (novels.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.homeFeedItems, [
            for (var i = 0; i < novels.length; i++)
              HomeFeedItemsCompanion.insert(section: section, position: i, novelId: novels[i].id),
          ]);
        });
      }
    });
    await _db.touchSync('home:$section');
  }

  Stream<List<NovelModel>> watchHomeFeed(String section) {
    final query = _db.select(_db.homeFeedItems).join([
      innerJoin(_db.novels, _db.novels.id.equalsExp(_db.homeFeedItems.novelId)),
    ])
      ..where(_db.homeFeedItems.section.equals(section))
      ..orderBy([OrderingTerm.asc(_db.homeFeedItems.position)]);
    return query.watch().map((rows) => rows.map((r) => r.readTable(_db.novels).toModel()).toList());
  }

  Future<void> saveNovelDetail(NovelModel novel) => upsertNovels([novel]);

  Future<NovelModel?> getCachedNovel(String idOrSlug) async {
    final query = _db.select(_db.novels)
      ..where((t) => t.id.equals(idOrSlug) | t.slug.equals(idOrSlug))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.toModel();
  }
}

final novelsRepositoryProvider = Provider<NovelsRepository>((ref) {
  return NovelsRepository(ref.watch(appDatabaseProvider));
});
